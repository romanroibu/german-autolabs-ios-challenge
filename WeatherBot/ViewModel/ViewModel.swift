//
//  ViewModel.swift
//  WeatherBot
//
//  Created by Roman Roibu on 27/12/2016.
//  Copyright © 2016 Roman Roibu. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

struct DialogUpdate {
    enum Part {
        case question
        case answer
    }
    enum Action {
        case insert
        case delete
        case update
    }

    let part: Part
    let action: Action
}

final class ViewModel<CA: ConversationalAgentService> {
    typealias Question = String
    typealias Answer = (icon: String?, summary: Summarizer.Summary)
    typealias SpokenAnswer = (answer: Answer, spokenRange: NSRange)

    typealias FailureSignal       = Signal<Error, NoError>
    typealias DialogUpdateSignal  = Signal<[DialogUpdate], NoError>
    typealias AgentActivitySignal = Signal<Bool, NoError>

    private typealias ListeningSignal = Signal<Void, NoError>

    var question: Question?

    var spokenAnswer: SpokenAnswer?

    var failure: FailureSignal {
        return self.failurePipe.output
    }

    var dialogUpdate: DialogUpdateSignal {
        return self.dialogUpdatePipe.output
    }

    var agentActivity: AgentActivitySignal {
        return self.agentActivityPipe.output
    }

    private var currentAnswer: Disposable?
    private var listeningPipe     = ListeningSignal.pipe()
    private let failurePipe       = FailureSignal.pipe()
    private let dialogUpdatePipe  = DialogUpdateSignal.pipe()
    private let agentActivityPipe = AgentActivitySignal.pipe()
    private let agent: CA

    init(agent: CA) {
        self.agent = agent
    }

    deinit {
        self.failurePipe.input.sendCompleted()
        self.listeningPipe.input.sendCompleted()
        self.dialogUpdatePipe.input.sendCompleted()
        self.agentActivityPipe.input.sendCompleted()
        self.currentAnswer?.dispose()
    }

    func startListening() {
        self.currentAnswer?.dispose()
        self.currentAnswer = nil

        self.agent.question(listenUntil: self.listeningPipe.output)
            .on(started: {
                    var updates: [DialogUpdate] = []
                    if self.spokenAnswer != nil {
                        self.spokenAnswer = nil
                        updates.append(DialogUpdate(part: .answer,   action: .delete))
                    }
                    if self.question != nil {
                        self.question = nil
                        updates.append(DialogUpdate(part: .question, action: .delete))
                    }
                    if !updates.isEmpty {
                        self.dialogUpdatePipe.input.send(value: updates)
                    }
                },
                failed: { error in
                    self.failurePipe.input.send(value: error)
                },
                value: { question in
                    //Operation order is important!
                    let update = self.question == nil
                        ? DialogUpdate(part: .question, action: .insert)
                        : DialogUpdate(part: .question, action: .update)
                    self.question = question
                    self.dialogUpdatePipe.input.send(value: [update])
                })
            .startWithSignal { signal, disposable in
                self.currentAnswer = self.agent.spokenAnswer(from: signal)
                    .on(starting: {
                            self.agentActivityPipe.input.send(value: true)
                        },
                        failed: { error in
                            self.failurePipe.input.send(value: error)
                        },
                        terminated: {
                            self.agentActivityPipe.input.send(value: false)
                        },
                        value: { spokenAnswer in
                            //Operation order is important!
                            let update = self.spokenAnswer == nil
                                ? DialogUpdate(part: .answer, action: .insert)
                                : DialogUpdate(part: .answer, action: .update)
                            self.spokenAnswer = spokenAnswer
                            self.dialogUpdatePipe.input.send(value: [update])
                        })
                    .logEvents()
                    .start()
        }
    }

    func stopListening() {
        self.listeningPipe.input.sendCompleted()
        self.listeningPipe = ListeningSignal.pipe()
    }
}

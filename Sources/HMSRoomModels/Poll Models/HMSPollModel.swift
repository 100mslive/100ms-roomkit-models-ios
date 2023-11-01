//
//  HMSPollModel.swift
//  HMSRoomKitDevelopment
//
//  Created by Pawan Dixit on 10/31/23.
//

import SwiftUI
import HMSSDK

public class HMSPollModel: ObservableObject, Hashable {
    
    public static func == (lhs: HMSPollModel, rhs: HMSPollModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    private var builder: HMSPollBuilder?
    weak var roomModel: HMSRoomModel?
    let poll: HMSPoll
    init(poll: HMSPoll, roomModel: HMSRoomModel) {
        self.roomModel = roomModel
        self.poll = poll
        
        id = poll.pollID
        result = poll.result
        questions = poll.questions
        state = poll.state
        stoppedAt = poll.stoppedAt
        startedAt = poll.startedAt
    }
    
    public init(title: String, type: HMSPollCategory) {
        builder = HMSPollBuilder().withCategory(type)
        
//        questions.forEach { questionModel in
//            switch questionModel.question.type {
//            case .singleChoice:
//                pollBuilder = pollBuilder.addSingleChoiceQuestion(with: questionModel.text, options: (questionModel.options)?.map{$0.text} ?? [])
//            case .multipleChoice:
//                pollBuilder = pollBuilder.addMultiChoiceQuestion(with: questionModel.text, options: (questionModel.options)?.map{$0.text} ?? [])
//            case .shortAnswer:
//                pollBuilder = pollBuilder.addShortAnswerQuestion(with: questionModel.text)
//            case .longAnswer:
//                pollBuilder = pollBuilder.addLongAnswerQuestion(with: questionModel.text)
//            @unknown default:
//                fatalError()
//            }
//        }
        
        self.poll = builder!.build()
        
        id = poll.pollID
        result = poll.result
        self.questions = poll.questions
        state = poll.state
        stoppedAt = poll.stoppedAt
        startedAt = poll.startedAt
    }
    
    public let id: String
    
    @Published private(set) public var result: HMSPollResult?
    @Published private(set) public var questions: [HMSPollQuestion]?
    @Published private(set) public var state: HMSPollState
    @Published private(set) public var stoppedAt: Date?
    @Published private(set) public var startedAt: Date?
}

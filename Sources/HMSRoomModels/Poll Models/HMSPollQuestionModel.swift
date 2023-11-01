//
//  HMSPollQuestionModel.swift
//  HMSRoomKitPreview
//
//  Created by Pawan Dixit on 10/31/23.
//

import SwiftUI
import HMSSDK

public class HMSPollQuestionModel: ObservableObject {
    
    let question: HMSPollQuestion
    init(question: HMSPollQuestion) {
        self.question = question
        responses = question.responses
        myResponses = question.myResponses
        text = question.text
        options = question.options
        type = question.type
    }
    
    public init(type: HMSPollQuestionType = .singleChoice,
                title: String,
                duration: Int = 0,
                isSkippable: Bool = false,
                options: [String]) {
        
        var questionBuilder = HMSPollQuestionBuilder()
                                .withType(type)
                                .withTitle(title)
                                .withDuration(duration)
                                .withCanBeSkipped(isSkippable)
        
        options.forEach {
            questionBuilder = questionBuilder.addOption(with: $0)
        }
        
        self.question = questionBuilder.build()
        responses = question.responses
        myResponses = question.myResponses
        text = question.text
        self.options = question.options
        self.type = question.type
    }
    
    public let text: String
    public let type: HMSPollQuestionType
    public let options: [HMSPollQuestionOption]?
    
    public var responses: [HMSPollQuestionResponse]?
    public var myResponses: [HMSPollQuestionResponse]
}

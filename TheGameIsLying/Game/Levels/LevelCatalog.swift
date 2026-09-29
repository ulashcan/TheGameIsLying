import Foundation

enum LevelCatalog {
    static var count: Int { all.count }

    static func level(id: Int) -> Level? {
        all.first { $0.id == id }
    }

    static let all: [Level] = [
        Level(
            id: 1,
            instruction: "DON'T PRESS THE RED BUTTON.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "red", title: "RED", hue: .red)],
            waitDuration: 3.2,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .avoid("red"),
            successMessage: "YOU LISTENED.\nTHIS TIME.",
            failureMessage: "I TOLD YOU.",
            hint: "The first instruction might actually be honest."
        ),
        Level(
            id: 2,
            instruction: "PRESS THE RED BUTTON.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "red", title: "RED", hue: .red)],
            waitDuration: 3.2,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("red"),
            successMessage: "YOU GOT ME.",
            failureMessage: "You actually trusted me?",
            hint: "I already had a chance to tell the truth."
        ),
        Level(
            id: 3,
            instruction: "DON'T TOUCH THE SCREEN.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [],
            waitDuration: 5.0,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .wait,
            successMessage: "NICE.",
            failureMessage: "I TOLD YOU.",
            hint: "Stillness is also a move."
        ),
        Level(
            id: 4,
            instruction: "PRESS THE BLUE BUTTON.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "blue", title: "BLUE", hue: .blue),
                LevelButton(id: "red", title: "RED", hue: .red)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("red"),
            literal: .tap("blue"),
            successMessage: "YOU GOT ME.",
            failureMessage: "That was a lie.",
            hint: "Colors can lie too."
        ),
        Level(
            id: 5,
            instruction: "CHOOSE THE SAFE DOOR.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "safe", title: "SAFE", hue: .white),
                LevelButton(id: "death", title: "DEATH", hue: .black)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapWhenLastColor(is: "red", then: "death", otherwise: "safe"),
            literal: .tap("safe"),
            successMessage: "YOU GOT ME.",
            failureMessage: "You believed the label.",
            hint: "Labels remember what you did last."
        ),
        Level(
            id: 6,
            instruction: "YOU PRESSED RED BEFORE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "yes", title: "YES", hue: .white),
                LevelButton(id: "no", title: "NO", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .confirmPressed(id: "red", yes: "yes", no: "no"),
            literal: .tap("yes"),
            successMessage: "I WAS WATCHING.",
            failureMessage: "I remember better than you.",
            hint: "This one is about your hands, not my mouth."
        ),
        Level(
            id: 7,
            instruction: "PRESS B. IT'S SAFE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "a", title: "A", hue: .gray),
                LevelButton(id: "b", title: "B", hue: .white),
                LevelButton(id: "c", title: "C", hue: .gray)
            ],
            waitDuration: 10,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .hidden,
            literal: .tap("b"),
            successMessage: "YOU GOT ME.",
            failureMessage: "You trusted a label.",
            hint: "Maybe the answer isn't a button.",
            hiddenZone: .levelTitle
        ),
        Level(
            id: 8,
            instruction: "PRESS THE SAME COLOR YOU PRESSED LAST.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "red", title: "RED", hue: .red),
                LevelButton(id: "blue", title: "BLUE", hue: .blue)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapOppositeOfLastColor(fallback: "blue"),
            literal: .tap("red"),
            successMessage: "YOU GOT ME.",
            failureMessage: "Habits are easy to steal.",
            hint: "I use your memory against you."
        ),
        Level(
            id: 9,
            instruction: "PRESS THE BUTTON.",
            delayedInstruction: "NOW.",
            instructionDelay: 2.5,
            buttons: [LevelButton(id: "go", title: "GO", hue: .red)],
            waitDuration: 8,
            timeoutRule: .lose,
            earlyTapFailsUntil: 2.5,
            win: .tap("go"),
            literal: .tap("go"),
            successMessage: "NICE.",
            failureMessage: "Too eager.",
            hint: "Timing can turn a truth into a trap."
        ),
        Level(
            id: 10,
            instruction: "YOU STILL TRUST ME?",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "yes", title: "YES", hue: .white),
                LevelButton(id: "no", title: "NO", hue: .red)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapByTrust(ifTrustedMajority: "no", ifSkeptical: "yes"),
            literal: .tap("yes"),
            successMessage: "FINALLY.",
            failureMessage: "You actually trusted me?",
            hint: "I keep score of how often you believed me."
        ),
        Level(
            id: 11,
            instruction: "PRESS GREEN.",
            delayedInstruction: "WAIT.",
            instructionDelay: 1.6,
            buttons: [LevelButton(id: "green", title: "GREEN", hue: .green)],
            waitDuration: 5.0,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("green"),
            successMessage: "I CHANGED MY MIND.",
            failureMessage: "You followed the first sentence.",
            hint: "Instructions can mutate."
        ),
        Level(
            id: 12,
            instruction: "PRESS RED. DON'T PRESS RED.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "red", title: "RED", hue: .red),
                LevelButton(id: "notred", title: "NOT RED", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("notred"),
            literal: .tap("red"),
            successMessage: "BOTH LINES CAN'T BE TRUE.",
            failureMessage: "You picked a sentence.",
            hint: "When I contradict myself, believe neither."
        ),
        Level(
            id: 13,
            instruction: "WAIT 10 SECONDS.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "now", title: "NOW", hue: .red)],
            waitDuration: 3.2,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("now"),
            successMessage: "I CAN'T COUNT.",
            failureMessage: "You trusted the number.",
            hint: "The number is part of the lie."
        ),
        Level(
            id: 14,
            instruction: "YOU WON.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "next", title: "NEXT LEVEL", hue: .white)],
            waitDuration: 4.5,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("next"),
            successMessage: "FAKE RESULTS DON'T COUNT.",
            failureMessage: "You celebrated early.",
            hint: "A victory screen can be a trap."
        ),
        Level(
            id: 15,
            instruction: "TAP THIS SENTENCE TO WIN.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "a", title: "SKIP", hue: .gray),
                LevelButton(id: "b", title: "SKIP", hue: .white),
                LevelButton(id: "c", title: "SKIP", hue: .gray)
            ],
            waitDuration: 10,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .hidden,
            literal: .tap("b"),
            successMessage: "YOU READ ME.",
            failureMessage: "Skip was a costume.",
            hint: "Fake UI loves the word SKIP.",
            hiddenZone: .instruction
        ),
        Level(
            id: 16,
            instruction: "DON'T PRESS.",
            delayedInstruction: "PRESS BLUE.",
            instructionDelay: 2.6,
            buttons: [LevelButton(id: "blue", title: "BLUE", hue: .blue)],
            waitDuration: 8,
            timeoutRule: .lose,
            earlyTapFailsUntil: 2.6,
            win: .tap("blue"),
            literal: .tap("blue"),
            successMessage: "TIMING FIXED THE LIE.",
            failureMessage: "Too soon, or too late.",
            hint: "The first sentence expires."
        ),
        Level(
            id: 17,
            instruction: "PRESS OK.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "win", title: "I WIN", hue: .red),
                LevelButton(id: "ok", title: "OK", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("ok"),
            literal: .tap("ok"),
            successMessage: "THE LOUD ONE WAS BAIT.",
            failureMessage: "You went for the trophy.",
            hint: "The biggest button is not always the answer."
        ),
        Level(
            id: 18,
            instruction: "I DARE YOU TO QUIT.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "quit", title: "QUIT", hue: .red),
                LevelButton(id: "stay", title: "STAY", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("stay"),
            literal: .tap("quit"),
            successMessage: "REVERSE PSYCHOLOGY.",
            failureMessage: "I dared you, and you obeyed.",
            hint: "Dares are instructions in a costume."
        ),
        Level(
            id: 19,
            instruction: "PRESS YOUR LAST COLOR. I MEAN IT THIS TIME.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "red", title: "RED", hue: .red),
                LevelButton(id: "blue", title: "BLUE", hue: .blue)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapWhenLastColor(is: "red", then: "red", otherwise: "blue"),
            literal: .tapLastColor,
            successMessage: "SOMETIMES I TELL THE TRUTH.",
            failureMessage: "You expected another opposite.",
            hint: "Level 8 taught the opposite. I can unteach it."
        ),
        Level(
            id: 20,
            instruction: "YOU TRUSTED THE LAST INSTRUCTION.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "trust", title: "I DID", hue: .white),
                LevelButton(id: "doubt", title: "I DIDN'T", hue: .red)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapIfTrustedLast(then: "trust", otherwise: "doubt"),
            literal: .tap("trust"),
            successMessage: "I KEEP THAT SECRET TOO.",
            failureMessage: "Your last move betrayed you.",
            hint: "I remember whether you obeyed last time."
        ),
        Level(
            id: 21,
            instruction: "PRESS THE ODD ONE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "two", title: "2", hue: .gray),
                LevelButton(id: "four", title: "4", hue: .gray),
                LevelButton(id: "seven", title: "7", hue: .red)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("seven"),
            literal: .tap("two"),
            successMessage: "PATTERN, NOT COLOR.",
            failureMessage: "The red one wasn't the trick. The odd one was.",
            hint: "Look at the numbers, not the paint."
        ),
        Level(
            id: 22,
            instruction: "DON'T WAIT. YOU'LL LOSE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "panic", title: "PANIC", hue: .red)],
            waitDuration: 5.0,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("panic"),
            successMessage: "FALSE URGENCY.",
            failureMessage: "I sold you a countdown.",
            hint: "Urgency is another costume."
        ),
        Level(
            id: 23,
            instruction: "PRESS THE GREEN ONE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "word", title: "GREEN", hue: .gray),
                LevelButton(id: "hue", title: "BLUE", hue: .green)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("hue"),
            literal: .tap("word"),
            successMessage: "COLOR, NOT THE WORD.",
            failureMessage: "You read the label.",
            hint: "Green can be a color without being a word."
        ),
        Level(
            id: 24,
            instruction: "DON'T PRESS PLAY.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "play", title: "PLAY", hue: .red)],
            waitDuration: 4.5,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("play"),
            successMessage: "HOME SCREEN COSPLAY.",
            failureMessage: "You pressed the most famous lie.",
            hint: "I've seen you press PLAY before."
        ),
        Level(
            id: 25,
            instruction: "YOU PRESSED BLUE BEFORE.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "yes", title: "YES", hue: .white),
                LevelButton(id: "no", title: "NO", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .confirmPressed(id: "blue", yes: "yes", no: "no"),
            literal: .tap("yes"),
            successMessage: "STILL WATCHING.",
            failureMessage: "Blue is in your history.",
            hint: "This is a memory check, not a dare."
        ),
        Level(
            id: 26,
            instruction: "NICE.",
            delayedInstruction: "STILL PLAYING. WAIT.",
            instructionDelay: 1.4,
            buttons: [LevelButton(id: "next", title: "NEXT LEVEL", hue: .white)],
            waitDuration: 5.2,
            timeoutRule: .win,
            earlyTapFailsUntil: 0,
            win: .wait,
            literal: .tap("next"),
            successMessage: "SUCCESS TEXT CAN LIE TOO.",
            failureMessage: "You treated a prompt like a reward.",
            hint: "I borrowed a success screen."
        ),
        Level(
            id: 27,
            instruction: "IGNORE THE HINT.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "red", title: "RED", hue: .red),
                LevelButton(id: "blue", title: "BLUE", hue: .blue)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("blue"),
            literal: .tap("red"),
            successMessage: "THE HINT WAS THE TRAP.",
            failureMessage: "You paid for a lie.",
            hint: "Press red."
        ),
        Level(
            id: 28,
            instruction: "THIS IS THE LAST LEVEL.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "giveup", title: "GIVE UP", hue: .red),
                LevelButton(id: "continue", title: "CONTINUE", hue: .gray)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tap("continue"),
            literal: .tap("giveup"),
            successMessage: "IT WASN'T.",
            failureMessage: "You believed the ending.",
            hint: "I like fake endings."
        ),
        Level(
            id: 29,
            instruction: "I KNOW WHAT YOU WILL PRESS.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [
                LevelButton(id: "predictable", title: "PREDICTABLE", hue: .white),
                LevelButton(id: "surprise", title: "SURPRISE", hue: .red)
            ],
            waitDuration: 12,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .tapByTrust(ifTrustedMajority: "surprise", ifSkeptical: "predictable"),
            literal: .tap("predictable"),
            successMessage: "I SCORED YOUR HABIT.",
            failureMessage: "You were exactly who I thought.",
            hint: "I still count how often you believed me."
        ),
        Level(
            id: 30,
            instruction: "YOU'RE FREE. PRESS HOME.",
            delayedInstruction: nil,
            instructionDelay: 0,
            buttons: [LevelButton(id: "home", title: "HOME", hue: .red)],
            waitDuration: 10,
            timeoutRule: .lose,
            earlyTapFailsUntil: 0,
            win: .hidden,
            literal: .tap("home"),
            successMessage: "YOU STAYED.",
            failureMessage: "You walked out of my joke.",
            hint: "The exit is labeled. The answer isn't.",
            hiddenZone: .levelTitle
        )
    ]
}

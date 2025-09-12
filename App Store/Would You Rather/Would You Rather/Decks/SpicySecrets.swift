import Foundation

let spicySecrets = Deck(name: "Spicy Secrets", icon: "🌶️", questions: [
    Question(
        id: UUID(),
        text: "Would you rather have a passionate night with a stranger or a slow, sensual night with your crush?",
        optionA: "Passionate night with a stranger",
        optionB: "Slow, sensual night with your crush",
        challengeA: "Send a flirty text to a stranger.",
        challengeB: "Send a seductive message to your crush."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss in the rain or kiss under the stars?",
        optionA: "Kiss in the rain",
        optionB: "Kiss under the stars",
        challengeA: "Describe your perfect rainy kiss.",
        challengeB: "Describe your perfect starlit kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper a secret in someone's ear or get a secret whispered to you?",
        optionA: "Whisper a secret",
        optionB: "Get whispered to",
        challengeA: "Whisper a flirty secret to a player.",
        challengeB: "Listen closely and react."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the one to initiate a kiss or have it unexpectedly happen?",
        optionA: "Initiate the kiss",
        optionB: "Unexpected kiss",
        challengeA: "Demonstrate your best kiss move.",
        challengeB: "React with surprise to a kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear lingerie or go shirtless for a night?",
        optionA: "Wear lingerie",
        optionB: "Go shirtless",
        challengeA: "Describe your favorite lingerie piece.",
        challengeB: "Show off your best pose shirtless."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get a massage or give a massage?",
        optionA: "Get a massage",
        optionB: "Give a massage",
        challengeA: "Describe your ideal massage.",
        challengeB: "Pretend to give a massage."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner tease you or be teased by a group?",
        optionA: "Partner tease",
        optionB: "Group tease",
        challengeA: "Describe a teasing moment with your partner.",
        challengeB: "React to a playful group tease."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a spontaneous makeout session or a planned romantic evening?",
        optionA: "Spontaneous makeout",
        optionB: "Planned romantic evening",
        challengeA: "Describe your spontaneous makeout style.",
        challengeB: "Describe your ideal romantic plan."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be caught flirting or catch someone flirting with you?",
        optionA: "Be caught flirting",
        optionB: "Catch someone flirting",
        challengeA: "Act out a flirty moment.",
        challengeB: "Describe how you'd catch a flirt."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try roleplaying or be blindfolded?",
        optionA: "Roleplaying",
        optionB: "Blindfolded",
        challengeA: "Describe a roleplay character you'd try.",
        challengeB: "Describe how you'd feel blindfolded."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have morning sex or midnight sex?",
        optionA: "Morning sex",
        optionB: "Midnight sex",
        challengeA: "Describe your morning sex fantasy.",
        challengeB: "Describe your midnight sex fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss passionately for five minutes or get kissed gently for ten?",
        optionA: "Passionate kiss (5 mins)",
        optionB: "Gentle kiss (10 mins)",
        challengeA: "Perform a passionate kiss sound.",
        challengeB: "Perform a gentle kiss sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a sexy selfie or receive one?",
        optionA: "Send a selfie",
        optionB: "Receive a selfie",
        challengeA: "Pretend to send a sexy selfie.",
        challengeB: "React to receiving a sexy selfie."
    ),
    Question(
        id: UUID(),
        text: "Would you rather explore a new kink or revisit an old favorite?",
        optionA: "Explore new kink",
        optionB: "Old favorite",
        challengeA: "Describe a kink you want to try.",
        challengeB: "Describe your favorite kink."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dance seductively or be danced to?",
        optionA: "Dance seductively",
        optionB: "Be danced to",
        challengeA: "Show a sexy dance move.",
        challengeB: "Let someone guide your dance."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dominant or submissive for a night?",
        optionA: "Dominant",
        optionB: "Submissive",
        challengeA: "Describe your dominant style.",
        challengeB: "Describe your submissive style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a slow, teasing foreplay or jump straight to the main event?",
        optionA: "Slow foreplay",
        optionB: "Jump straight in",
        challengeA: "Describe your teasing foreplay.",
        challengeB: "Describe how you'd jump right in."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss with eyes open or eyes closed?",
        optionA: "Eyes open",
        optionB: "Eyes closed",
        challengeA: "Demonstrate a kiss with eyes open.",
        challengeB: "Demonstrate a kiss with eyes closed."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a secret rendezvous or a public flirtation?",
        optionA: "Secret rendezvous",
        optionB: "Public flirtation",
        challengeA: "Describe your secret meeting spot.",
        challengeB: "Describe your public flirting style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tickled or tickle someone else?",
        optionA: "Be tickled",
        optionB: "Tickle someone else",
        challengeA: "React to an imaginary tickle.",
        challengeB: "Pretend to tickle someone."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear a blindfold or handcuffs?",
        optionA: "Blindfold",
        optionB: "Handcuffs",
        challengeA: "Describe how blindfolded feels.",
        challengeB: "Describe how handcuffed feels."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a slow dance or a fast dance with someone you desire?",
        optionA: "Slow dance",
        optionB: "Fast dance",
        challengeA: "Pretend to slow dance.",
        challengeB: "Pretend to fast dance."
    ),
    Question(
        id: UUID(),
        text: "Would you rather receive a love letter or a love poem?",
        optionA: "Love letter",
        optionB: "Love poem",
        challengeA: "Write a quick love letter.",
        challengeB: "Recite a short love poem."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with ice cubes or warm feathers?",
        optionA: "Ice cubes",
        optionB: "Warm feathers",
        challengeA: "Describe the sensation of ice cubes.",
        challengeB: "Describe the sensation of feathers."
    ),
    Question(
        id: UUID(),
        text: "Would you rather slow dance with your eyes locked or with your hands exploring?",
        optionA: "Eyes locked",
        optionB: "Hands exploring",
        challengeA: "Lock eyes with someone for 10 seconds.",
        challengeB: "Pretend to explore gently."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a naughty secret or keep it to yourself?",
        optionA: "Share secret",
        optionB: "Keep secret",
        challengeA: "Tell a naughty secret (real or fake).",
        challengeB: "Explain why you’d keep a secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a candlelit bath or a steamy shower with someone special?",
        optionA: "Candlelit bath",
        optionB: "Steamy shower",
        challengeA: "Describe your bath setup.",
        challengeB: "Describe your shower moment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on the neck or on the ear?",
        optionA: "Neck",
        optionB: "Ear",
        challengeA: "Make a kissing sound on the neck.",
        challengeB: "Make a kissing sound on the ear."
    ),
    Question(
        id: UUID(),
        text: "Would you rather slow seduce or wild seduce?",
        optionA: "Slow seduce",
        optionB: "Wild seduce",
        challengeA: "Describe your slow seduction technique.",
        challengeB: "Describe your wild seduction style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a secret admirer or be a secret admirer?",
        optionA: "Secret admirer",
        optionB: "Be secret admirer",
        challengeA: "Describe what you think about a secret admirer.",
        challengeB: "Describe your secret admirer moves."
    ),
    Question(
        id: UUID(),
        text: "Would you rather receive a lap dance or give a lap dance?",
        optionA: "Receive lap dance",
        optionB: "Give lap dance",
        challengeA: "Describe a lap dance you’d enjoy.",
        challengeB: "Demonstrate a dance move."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be caught making out or caught flirting on the phone?",
        optionA: "Making out",
        optionB: "Flirting on phone",
        challengeA: "Act surprised by getting caught.",
        challengeB: "Describe a flirty phone convo."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a new sex position or revisit a classic favorite?",
        optionA: "New position",
        optionB: "Classic favorite",
        challengeA: "Describe a new position you want to try.",
        challengeB: "Describe your favorite classic."
    ),
    Question(
        id: UUID(),
        text: "Would you rather go on a sexy photo shoot or watch one?",
        optionA: "Go on shoot",
        optionB: "Watch shoot",
        challengeA: "Describe your ideal photo shoot pose.",
        challengeB: "Describe your favorite photo to watch."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease with words or with touch?",
        optionA: "Words",
        optionB: "Touch",
        challengeA: "Say a sexy line to someone.",
        challengeB: "Pretend to touch someone's arm."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be pampered all night or pamper someone else all night?",
        optionA: "Be pampered",
        optionB: "Pamper someone",
        challengeA: "Describe your pampering fantasy.",
        challengeB: "Describe how you'd pamper someone."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a new adult toy or introduce your favorite toy to someone?",
        optionA: "Try new toy",
        optionB: "Introduce favorite toy",
        challengeA: "Describe a toy you want to try.",
        challengeB: "Describe your favorite toy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dress up in costume or go natural?",
        optionA: "Dress up",
        optionB: "Go natural",
        challengeA: "Describe your favorite costume.",
        challengeB: "Describe what going natural means to you."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with ice or fire?",
        optionA: "Ice",
        optionB: "Fire",
        challengeA: "Describe the feeling of ice teasing.",
        challengeB: "Describe the feeling of fire teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather slow kiss or make out wildly?",
        optionA: "Slow kiss",
        optionB: "Make out wildly",
        challengeA: "Demonstrate a slow kiss sound.",
        challengeB: "Demonstrate a wild makeout sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be surprised with breakfast in bed or with a sexy note?",
        optionA: "Breakfast in bed",
        optionB: "Sexy note",
        challengeA: "Describe your perfect breakfast.",
        challengeB: "Write a quick sexy note."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have candle wax play or ice cube play?",
        optionA: "Candle wax",
        optionB: "Ice cubes",
        challengeA: "Describe candle wax sensation.",
        challengeB: "Describe ice cube sensation."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a secret fantasy or watch someone share theirs?",
        optionA: "Share your fantasy",
        optionB: "Watch someone share",
        challengeA: "Reveal a fantasy.",
        challengeB: "Listen and react."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss slowly all over someone's body or fast on their lips?",
        optionA: "Slow kisses over body",
        optionB: "Fast kisses on lips",
        challengeA: "Demonstrate slow kisses.",
        challengeB: "Demonstrate fast kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with food or drink?",
        optionA: "Food",
        optionB: "Drink",
        challengeA: "Describe a teasing food moment.",
        challengeB: "Describe a teasing drink moment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a sexy voice message or receive one?",
        optionA: "Send voice message",
        optionB: "Receive voice message",
        challengeA: "Record a sexy phrase aloud.",
        challengeB: "React to a sexy phrase."
    ),
    Question(
        id: UUID(),
        text: "Would you rather explore outdoors or indoors for a naughty adventure?",
        optionA: "Outdoors",
        optionB: "Indoors",
        challengeA: "Describe an outdoor adventure.",
        challengeB: "Describe an indoor adventure."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the teacher or the student in a naughty lesson?",
        optionA: "Teacher",
        optionB: "Student",
        challengeA: "Describe your lesson plan.",
        challengeB: "Describe your student role."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tickled gently or tickled hard?",
        optionA: "Gently",
        optionB: "Hard",
        challengeA: "React to gentle tickle.",
        challengeB: "React to hard tickle."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner whisper sweet nothings or loud compliments?",
        optionA: "Whisper sweet nothings",
        optionB: "Loud compliments",
        challengeA: "Whisper a sweet nothing.",
        challengeB: "Shout a compliment playfully."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with slow kisses or quick touches?",
        optionA: "Slow kisses",
        optionB: "Quick touches",
        challengeA: "Describe slow kiss teasing.",
        challengeB: "Describe quick touch teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a new sexy outfit or go with something comfortable but flirty?",
        optionA: "New sexy outfit",
        optionB: "Comfortable but flirty",
        challengeA: "Describe your sexy outfit.",
        challengeB: "Describe your comfy flirty look."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a flirty text first or wait to be texted?",
        optionA: "Send first",
        optionB: "Wait to be texted",
        challengeA: "Compose a flirty opening text.",
        challengeB: "Describe your reaction when texted."
    )
])

import Foundation

let naughtyChoices = Deck(name: "Naughty Choices", icon: "😈", questions: [
    Question(
        id: UUID(),
        text: "Would you rather send a risqué photo or receive one?",
        optionA: "Send a risqué photo",
        optionB: "Receive a risqué photo",
        challengeA: "Describe the photo you would send.",
        challengeB: "React to receiving a risqué photo."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a one-night stand or a friends-with-benefits situation?",
        optionA: "One-night stand",
        optionB: "Friends-with-benefits",
        challengeA: "Describe your ideal one-night stand.",
        challengeB: "Describe your ideal friends-with-benefits."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a new kinky toy or play with food?",
        optionA: "New kinky toy",
        optionB: "Play with food",
        challengeA: "Describe the toy you'd try.",
        challengeB: "Describe your favorite food play."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tied up or do the tying?",
        optionA: "Be tied up",
        optionB: "Do the tying",
        challengeA: "Describe how it feels to be tied up.",
        challengeB: "Describe your tying style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in a public place or a secret private spot?",
        optionA: "Public place",
        optionB: "Secret private spot",
        challengeA: "Describe the public place you’d choose.",
        challengeB: "Describe your secret spot."
    ),
    Question(
        id: UUID(),
        text: "Would you rather talk dirty or whisper sweet things?",
        optionA: "Talk dirty",
        optionB: "Whisper sweet things",
        challengeA: "Say a dirty line aloud.",
        challengeB: "Whisper a sweet phrase."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a quickie or a long, slow session?",
        optionA: "Quickie",
        optionB: "Long, slow session",
        challengeA: "Describe your quickie fantasy.",
        challengeB: "Describe your long session fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner dress up for you or you dress up for them?",
        optionA: "Partner dresses up",
        optionB: "You dress up",
        challengeA: "Describe their outfit.",
        challengeB: "Describe your outfit."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be blindfolded or handcuffed during play?",
        optionA: "Blindfolded",
        optionB: "Handcuffed",
        challengeA: "Describe the blindfolded sensation.",
        challengeB: "Describe being handcuffed."
    ),
    Question(
        id: UUID(),
        text: "Would you rather receive a striptease or give one?",
        optionA: "Receive striptease",
        optionB: "Give striptease",
        challengeA: "Describe how the striptease makes you feel.",
        challengeB: "Describe your striptease moves."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss passionately in public or flirt discreetly?",
        optionA: "Kiss passionately",
        optionB: "Flirt discreetly",
        challengeA: "Act out a passionate kiss.",
        challengeB: "Describe your discreet flirting."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a sexy fantasy or keep it secret?",
        optionA: "Share fantasy",
        optionB: "Keep secret",
        challengeA: "Reveal your fantasy.",
        challengeB: "Explain why you'd keep it secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who’s adventurous or more traditional?",
        optionA: "Adventurous",
        optionB: "Traditional",
        challengeA: "Describe your adventurous ideal.",
        challengeB: "Describe your traditional ideal."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try spanking or being spanked?",
        optionA: "Try spanking",
        optionB: "Being spanked",
        challengeA: "Describe your spanking style.",
        challengeB: "Describe how it feels to be spanked."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex with lights on or lights off?",
        optionA: "Lights on",
        optionB: "Lights off",
        challengeA: "Describe your lights on fantasy.",
        challengeB: "Describe your lights off fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper sexy compliments or shout them out loud?",
        optionA: "Whisper compliments",
        optionB: "Shout compliments",
        challengeA: "Whisper a sexy compliment.",
        challengeB: "Shout a sexy compliment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed all over or kissed only on the lips?",
        optionA: "All over",
        optionB: "Only lips",
        challengeA: "Describe kisses all over.",
        challengeB: "Describe lip kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with ice or with warm breath?",
        optionA: "Ice",
        optionB: "Warm breath",
        challengeA: "Describe the feeling of ice teasing.",
        challengeB: "Describe the feeling of warm breath."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try sexting all day or sending voice messages all night?",
        optionA: "Sext all day",
        optionB: "Voice messages all night",
        challengeA: "Send a flirty text now.",
        challengeB: "Send a sexy voice message now."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the one to initiate sex or have your partner initiate?",
        optionA: "You initiate",
        optionB: "Partner initiates",
        challengeA: "Describe how you’d initiate.",
        challengeB: "Describe how they’d initiate."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a new sex position or revisit your favorite?",
        optionA: "New position",
        optionB: "Favorite position",
        challengeA: "Describe a position you want to try.",
        challengeB: "Describe your favorite position."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex outdoors or indoors?",
        optionA: "Outdoors",
        optionB: "Indoors",
        challengeA: "Describe your ideal outdoor location.",
        challengeB: "Describe your ideal indoor spot."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who is vocal or silent during sex?",
        optionA: "Vocal",
        optionB: "Silent",
        challengeA: "Describe how vocal partner excites you.",
        challengeB: "Describe how silent partner excites you."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on the neck or on the ears?",
        optionA: "Neck",
        optionB: "Ears",
        challengeA: "Make a neck kiss sound.",
        challengeB: "Make an ear kiss sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who loves to cuddle or who loves to tease?",
        optionA: "Cuddle",
        optionB: "Tease",
        challengeA: "Describe your cuddling style.",
        challengeB: "Describe your teasing style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in the morning or at night?",
        optionA: "Morning",
        optionB: "Night",
        challengeA: "Describe your morning sex fantasy.",
        challengeB: "Describe your night sex fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed slowly or passionately?",
        optionA: "Slowly",
        optionB: "Passionately",
        challengeA: "Demonstrate a slow kiss sound.",
        challengeB: "Demonstrate a passionate kiss sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather receive a sexy text or a sexy call?",
        optionA: "Text",
        optionB: "Call",
        challengeA: "Write a sexy text now.",
        challengeB: "Pretend to answer a sexy call."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dominant or submissive?",
        optionA: "Dominant",
        optionB: "Submissive",
        challengeA: "Describe your dominant role.",
        challengeB: "Describe your submissive role."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with a feather or with ice cubes?",
        optionA: "Feather",
        optionB: "Ice cubes",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe ice cube teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your hands or your lips?",
        optionA: "Hands",
        optionB: "Lips",
        challengeA: "Demonstrate a hand kiss.",
        challengeB: "Demonstrate a lip kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a naughty message first or wait for one?",
        optionA: "Send first",
        optionB: "Wait for message",
        challengeA: "Compose a naughty opener.",
        challengeB: "Describe your reaction when you receive one."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be surprised with chocolate or champagne?",
        optionA: "Chocolate",
        optionB: "Champagne",
        challengeA: "Describe your favorite chocolate.",
        challengeB: "Describe your favorite champagne."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease your partner or be teased?",
        optionA: "Tease partner",
        optionB: "Be teased",
        challengeA: "Describe a teasing moment.",
        challengeB: "Describe being teased."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have slow, teasing kisses or fast, urgent kisses?",
        optionA: "Slow teasing",
        optionB: "Fast urgent",
        challengeA: "Demonstrate slow kisses.",
        challengeB: "Demonstrate fast kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in the shower or in bed?",
        optionA: "Shower",
        optionB: "Bed",
        challengeA: "Describe your shower fantasy.",
        challengeB: "Describe your bed fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your stomach or on your thighs?",
        optionA: "Stomach",
        optionB: "Thighs",
        challengeA: "Make a kissing sound on the stomach.",
        challengeB: "Make a kissing sound on the thighs."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a sensual massage or give one?",
        optionA: "Receive massage",
        optionB: "Give massage",
        challengeA: "Describe your favorite massage spot.",
        challengeB: "Pretend to massage someone."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try roleplay or watch a sexy movie together?",
        optionA: "Roleplay",
        optionB: "Sexy movie",
        challengeA: "Describe your roleplay character.",
        challengeB: "Describe your favorite sexy movie scene."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a naughty text to a crush or to a friend?",
        optionA: "Crush",
        optionB: "Friend",
        challengeA: "Write a naughty text for a crush.",
        challengeB: "Write a naughty text for a friend."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your collarbone or on your back?",
        optionA: "Collarbone",
        optionB: "Back",
        challengeA: "Make a kissing sound on the collarbone.",
        challengeB: "Make a kissing sound on the back."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with chocolate syrup or whipped cream?",
        optionA: "Chocolate syrup",
        optionB: "Whipped cream",
        challengeA: "Describe chocolate syrup teasing.",
        challengeB: "Describe whipped cream teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner whisper in your ear or breathe on your neck?",
        optionA: "Whisper in ear",
        optionB: "Breathe on neck",
        challengeA: "Whisper a sexy phrase.",
        challengeB: "Describe how breathing on your neck feels."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give your partner a naughty nickname or receive one?",
        optionA: "Give nickname",
        optionB: "Receive nickname",
        challengeA: "Create a naughty nickname.",
        challengeB: "React to a naughty nickname."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try body painting or take sexy photos?",
        optionA: "Body painting",
        optionB: "Sexy photos",
        challengeA: "Describe a body painting idea.",
        challengeB: "Describe your sexy photo pose."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your fingertips or on your ears?",
        optionA: "Fingertips",
        optionB: "Ears",
        challengeA: "Demonstrate fingertip kisses.",
        challengeB: "Demonstrate ear kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who loves to kiss or loves to touch?",
        optionA: "Loves to kiss",
        optionB: "Loves to touch",
        challengeA: "Describe your kissing ideal.",
        challengeB: "Describe your touching ideal."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased by light tickling or soft biting?",
        optionA: "Light tickling",
        optionB: "Soft biting",
        challengeA: "Describe light tickling sensation.",
        challengeB: "Describe soft biting sensation."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex while listening to loud music or complete silence?",
        optionA: "Loud music",
        optionB: "Silence",
        challengeA: "Describe your loud music playlist.",
        challengeB: "Describe why silence excites you."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss your partner’s neck or their lips first?",
        optionA: "Neck first",
        optionB: "Lips first",
        challengeA: "Describe kissing the neck.",
        challengeB: "Describe kissing the lips."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who loves to surprise you or who loves routine?",
        optionA: "Loves surprises",
        optionB: "Loves routine",
        challengeA: "Describe a surprise you'd love.",
        challengeB: "Describe your favorite routine."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper a secret fantasy or reveal it in writing?",
        optionA: "Whisper fantasy",
        optionB: "Reveal in writing",
        challengeA: "Whisper your fantasy now.",
        challengeB: "Write a secret fantasy now."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who loves cuddling after sex or wants space?",
        optionA: "Loves cuddling",
        optionB: "Wants space",
        challengeA: "Describe your ideal cuddle.",
        challengeB: "Describe how you enjoy alone time."
    )
])

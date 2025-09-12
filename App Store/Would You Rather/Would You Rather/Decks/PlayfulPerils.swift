import Foundation

let playfulPerils = Deck(name: "Playful Perils", icon: "🎲", questions: [
    Question(
        id: UUID(),
        text: "Would you rather get tickled relentlessly or tickle your partner?",
        optionA: "Get tickled",
        optionB: "Tickle partner",
        challengeA: "Describe how tickling feels.",
        challengeB: "Describe your tickling technique."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play truth or dare or never have to choose?",
        optionA: "Truth or Dare",
        optionB: "Never choose",
        challengeA: "Give a daring challenge.",
        challengeB: "Explain why you avoid choosing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a blindfold or noise-cancelling headphones during play?",
        optionA: "Blindfold",
        optionB: "Headphones",
        challengeA: "Describe sensations with blindfold.",
        challengeB: "Describe sensations with headphones."
    ),
    Question(
        id: UUID(),
        text: "Would you rather spin a bottle or play strip poker?",
        optionA: "Spin a bottle",
        optionB: "Strip poker",
        challengeA: "Describe a spin-the-bottle scenario.",
        challengeB: "Describe a strip poker move."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you can only whisper or only shout?",
        optionA: "Only whisper",
        optionB: "Only shout",
        challengeA: "Whisper a secret.",
        challengeB: "Shout a silly phrase."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play charades or Pictionary with naughty topics?",
        optionA: "Charades",
        optionB: "Pictionary",
        challengeA: "Act out a naughty phrase.",
        challengeB: "Draw a naughty picture."
    ),
    Question(
        id: UUID(),
        text: "Would you rather use ice cubes or whipped cream during play?",
        optionA: "Ice cubes",
        optionB: "Whipped cream",
        challengeA: "Describe the feeling of ice.",
        challengeB: "Describe the feeling of cream."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give a lap dance or receive one?",
        optionA: "Give lap dance",
        optionB: "Receive lap dance",
        challengeA: "Describe your lap dance moves.",
        challengeB: "Describe how it feels to receive."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game of seduction or a game of teasing?",
        optionA: "Seduction",
        optionB: "Teasing",
        challengeA: "Describe a seductive move.",
        challengeB: "Describe a teasing technique."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a tickle fight or a pillow fight?",
        optionA: "Tickle fight",
        optionB: "Pillow fight",
        challengeA: "Describe a tickle fight moment.",
        challengeB: "Describe a pillow fight moment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tied up with silk scarves or leather cuffs?",
        optionA: "Silk scarves",
        optionB: "Leather cuffs",
        challengeA: "Describe silk scarf restraint.",
        challengeB: "Describe leather cuff restraint."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game with blindfolds or with restraints?",
        optionA: "Blindfolds",
        optionB: "Restraints",
        challengeA: "Describe blindfold sensations.",
        challengeB: "Describe restraint sensations."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased verbally or physically?",
        optionA: "Verbally",
        optionB: "Physically",
        challengeA: "Give a teasing line.",
        challengeB: "Describe physical teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather take turns giving compliments or dares?",
        optionA: "Compliments",
        optionB: "Dares",
        challengeA: "Give a genuine compliment.",
        challengeB: "Give a daring challenge."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you only communicate with touch or only with eye contact?",
        optionA: "Touch",
        optionB: "Eye contact",
        challengeA: "Describe communicating by touch.",
        challengeB: "Describe communicating by eye contact."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner feed you or be fed by you?",
        optionA: "Be fed",
        optionB: "Feed partner",
        challengeA: "Describe being fed.",
        challengeB: "Describe feeding partner."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game with music or silence?",
        optionA: "Music",
        optionB: "Silence",
        challengeA: "Describe a sexy song choice.",
        challengeB: "Describe the power of silence."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with ice or with warm breath?",
        optionA: "Ice",
        optionB: "Warm breath",
        challengeA: "Describe ice teasing.",
        challengeB: "Describe warm breath teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give a sensual massage or receive one?",
        optionA: "Give massage",
        optionB: "Receive massage",
        challengeA: "Describe your massage style.",
        challengeB: "Describe how it feels to receive."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game of strip trivia or strip charades?",
        optionA: "Strip trivia",
        optionB: "Strip charades",
        challengeA: "Give a trivia question.",
        challengeB: "Act out a charade."
    ),
    Question(
        id: UUID(),
        text: "Would you rather use feathers or silk during play?",
        optionA: "Feathers",
        optionB: "Silk",
        challengeA: "Describe feather play.",
        challengeB: "Describe silk play."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner whisper in your ear or kiss your neck?",
        optionA: "Whisper",
        optionB: "Kiss neck",
        challengeA: "Describe a whisper.",
        challengeB: "Describe a neck kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you can only speak in questions or only in statements?",
        optionA: "Only questions",
        optionB: "Only statements",
        challengeA: "Ask a sexy question.",
        challengeB: "Make a sexy statement."
    ),
    Question(
        id: UUID(),
        text: "Would you rather take a dare or tell a secret?",
        optionA: "Take dare",
        optionB: "Tell secret",
        challengeA: "Describe the dare.",
        challengeB: "Reveal a secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear something sexy or nothing at all during play?",
        optionA: "Something sexy",
        optionB: "Nothing at all",
        challengeA: "Describe your sexy outfit.",
        challengeB: "Describe the feeling of nothing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game that involves ice cubes or whipped cream?",
        optionA: "Ice cubes",
        optionB: "Whipped cream",
        challengeA: "Describe ice cube sensations.",
        challengeB: "Describe whipped cream sensations."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with a feather or with fingertips?",
        optionA: "Feather",
        optionB: "Fingertips",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe fingertip teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try roleplay as a boss or a personal assistant?",
        optionA: "Boss",
        optionB: "Personal assistant",
        challengeA: "Describe boss role.",
        challengeB: "Describe assistant role."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper naughty secrets or shout silly dares?",
        optionA: "Whisper secrets",
        optionB: "Shout dares",
        challengeA: "Whisper a naughty secret.",
        challengeB: "Shout a silly dare."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you can only move slowly or only move quickly?",
        optionA: "Move slowly",
        optionB: "Move quickly",
        challengeA: "Describe slow movement.",
        challengeB: "Describe quick movement."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tickled on your feet or on your sides?",
        optionA: "Feet",
        optionB: "Sides",
        challengeA: "Describe tickling feet.",
        challengeB: "Describe tickling sides."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game with blindfolds or with glow sticks?",
        optionA: "Blindfolds",
        optionB: "Glow sticks",
        challengeA: "Describe blindfold play.",
        challengeB: "Describe glow stick play."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give a seductive dance or receive one?",
        optionA: "Give dance",
        optionB: "Receive dance",
        challengeA: "Describe your dance moves.",
        challengeB: "Describe receiving a dance."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease your partner with words or actions?",
        optionA: "Words",
        optionB: "Actions",
        challengeA: "Give a teasing line.",
        challengeB: "Describe teasing action."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game that ends with a kiss or a tickle?",
        optionA: "Kiss",
        optionB: "Tickle",
        challengeA: "Describe a perfect kiss.",
        challengeB: "Describe a fun tickle."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be restrained gently or firmly?",
        optionA: "Gently",
        optionB: "Firmly",
        challengeA: "Describe gentle restraint.",
        challengeB: "Describe firm restraint."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give a slow strip tease or a playful one?",
        optionA: "Slow strip tease",
        optionB: "Playful strip tease",
        challengeA: "Describe slow tease.",
        challengeB: "Describe playful tease."
    ),
    Question(
        id: UUID(),
        text: "Would you rather use silk or leather for playtime?",
        optionA: "Silk",
        optionB: "Leather",
        challengeA: "Describe silk sensations.",
        challengeB: "Describe leather sensations."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with ice or with warm breath?",
        optionA: "Ice",
        optionB: "Warm breath",
        challengeA: "Describe ice teasing.",
        challengeB: "Describe warm breath teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you can only use compliments or only use dares?",
        optionA: "Compliments",
        optionB: "Dares",
        challengeA: "Give a compliment.",
        challengeB: "Give a dare."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tickled all over or just on your neck?",
        optionA: "All over",
        optionB: "Just neck",
        challengeA: "Describe full body tickling.",
        challengeB: "Describe neck tickling."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you must keep a straight face or laugh uncontrollably?",
        optionA: "Keep straight face",
        optionB: "Laugh uncontrollably",
        challengeA: "Describe keeping straight face.",
        challengeB: "Describe laughing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with a feather or a silk scarf?",
        optionA: "Feather",
        optionB: "Silk scarf",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe silk scarf teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be fed chocolate or strawberries by your partner?",
        optionA: "Chocolate",
        optionB: "Strawberries",
        challengeA: "Describe chocolate feeding.",
        challengeB: "Describe strawberry feeding."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game of naughty truth or dirty dare?",
        optionA: "Naughty truth",
        optionB: "Dirty dare",
        challengeA: "Answer a naughty truth.",
        challengeB: "Do a dirty dare."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed softly or passionately?",
        optionA: "Softly",
        optionB: "Passionately",
        challengeA: "Describe soft kiss.",
        challengeB: "Describe passionate kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game that involves only touch or only words?",
        optionA: "Only touch",
        optionB: "Only words",
        challengeA: "Describe a touch interaction.",
        challengeB: "Describe a words interaction."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased by a feather or a cold tongue?",
        optionA: "Feather",
        optionB: "Cold tongue",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe cold tongue teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner tease you verbally or with their hands?",
        optionA: "Verbally",
        optionB: "Hands",
        challengeA: "Give a teasing line.",
        challengeB: "Describe teasing touch."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game that ends with a tickle or a kiss?",
        optionA: "Tickle",
        optionB: "Kiss",
        challengeA: "Describe the tickle ending.",
        challengeB: "Describe the kiss ending."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be restrained with silk ribbons or handcuffs?",
        optionA: "Silk ribbons",
        optionB: "Handcuffs",
        challengeA: "Describe silk ribbons.",
        challengeB: "Describe handcuffs."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a slow strip tease or a fast one?",
        optionA: "Slow strip tease",
        optionB: "Fast strip tease",
        challengeA: "Describe slow tease.",
        challengeB: "Describe fast tease."
    )
])

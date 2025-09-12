import Foundation

let risquéDilemmas = Deck(name: "Risqué Dilemmas", icon: "🔥", questions: [
    Question(
        id: UUID(),
        text: "Would you rather have sex in the rain or on a sandy beach?",
        optionA: "In the rain",
        optionB: "On a sandy beach",
        challengeA: "Describe how the rain feels.",
        challengeB: "Describe the beach setting."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed with ice cubes or warm lips?",
        optionA: "Ice cubes",
        optionB: "Warm lips",
        challengeA: "Describe the sensation of ice.",
        challengeB: "Describe the feeling of warm kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tied up or tie someone else up?",
        optionA: "Be tied up",
        optionB: "Tie someone else up",
        challengeA: "Describe how it feels to be restrained.",
        challengeB: "Describe your tying style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner whisper fantasies or shout dirty talk?",
        optionA: "Whisper fantasies",
        optionB: "Shout dirty talk",
        challengeA: "Say a whispered fantasy aloud.",
        challengeB: "Say a shouted phrase aloud."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be blindfolded or have your partner blindfolded?",
        optionA: "Be blindfolded",
        optionB: "Blindfold your partner",
        challengeA: "Describe your feelings blindfolded.",
        challengeB: "Describe how you'd blindfold them."
    ),
    Question(
        id: UUID(),
        text: "Would you rather watch your partner undress or undress yourself slowly?",
        optionA: "Watch partner undress",
        optionB: "Undress slowly yourself",
        challengeA: "Describe what you notice watching.",
        challengeB: "Describe your slow undressing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather sext throughout the day or have an all-night phone call?",
        optionA: "Sext all day",
        optionB: "All-night phone call",
        challengeA: "Send a flirty text now.",
        challengeB: "Pretend to answer a sexy call."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dominant or submissive in bed?",
        optionA: "Dominant",
        optionB: "Submissive",
        challengeA: "Describe your dominant move.",
        challengeB: "Describe your submissive feeling."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a quickie or a marathon session?",
        optionA: "Quickie",
        optionB: "Marathon",
        challengeA: "Describe your ideal quickie.",
        challengeB: "Describe your marathon fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try roleplay or use toys?",
        optionA: "Roleplay",
        optionB: "Use toys",
        challengeA: "Describe a roleplay scenario.",
        challengeB: "Describe a toy you want to try."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss passionately or slowly tease with touches?",
        optionA: "Kiss passionately",
        optionB: "Tease with touches",
        challengeA: "Demonstrate a passionate kiss sound.",
        challengeB: "Describe teasing touches."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in a fancy hotel or at home?",
        optionA: "Fancy hotel",
        optionB: "At home",
        challengeA: "Describe your hotel fantasy.",
        challengeB: "Describe your home setup."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear lingerie or nothing at all?",
        optionA: "Lingerie",
        optionB: "Nothing at all",
        challengeA: "Describe your favorite lingerie.",
        challengeB: "Describe how it feels to be nude."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your neck or on your lips?",
        optionA: "Neck",
        optionB: "Lips",
        challengeA: "Make a neck kiss sound.",
        challengeB: "Make a lip kiss sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who is loud or silent during sex?",
        optionA: "Loud",
        optionB: "Silent",
        challengeA: "Describe how loud excites you.",
        challengeB: "Describe the thrill of silence."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased with feathers or ice cubes?",
        optionA: "Feathers",
        optionB: "Ice cubes",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe ice cube teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give your partner a striptease or receive one?",
        optionA: "Give striptease",
        optionB: "Receive striptease",
        challengeA: "Describe your striptease moves.",
        challengeB: "Describe how receiving feels."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed all over or kissed only on the lips?",
        optionA: "All over",
        optionB: "Only lips",
        challengeA: "Describe all-over kisses.",
        challengeB: "Describe lip kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex with lights on or lights off?",
        optionA: "Lights on",
        optionB: "Lights off",
        challengeA: "Describe your lights-on fantasy.",
        challengeB: "Describe your lights-off fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease your partner or be teased?",
        optionA: "Tease partner",
        optionB: "Be teased",
        challengeA: "Describe teasing moments.",
        challengeB: "Describe being teased."
    ),
    Question(
        id: UUID(),
        text: "Would you rather talk dirty or whisper sweet nothings?",
        optionA: "Talk dirty",
        optionB: "Whisper sweet nothings",
        challengeA: "Say a dirty line aloud.",
        challengeB: "Whisper a sweet phrase."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in the morning or at night?",
        optionA: "Morning",
        optionB: "Night",
        challengeA: "Describe morning fantasy.",
        challengeB: "Describe night fantasy."
    ),
    Question(
        id: UUID(),
        text: "Would you rather give a sensual massage or receive one?",
        optionA: "Give massage",
        optionB: "Receive massage",
        challengeA: "Describe your massage technique.",
        challengeB: "Describe your favorite massage spot."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your fingers or on your ears?",
        optionA: "Fingers",
        optionB: "Ears",
        challengeA: "Demonstrate finger kisses.",
        challengeB: "Demonstrate ear kisses."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who loves to cuddle or loves to tease?",
        optionA: "Cuddle",
        optionB: "Tease",
        challengeA: "Describe your cuddling style.",
        challengeB: "Describe your teasing style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a naughty text or a sexy voice message?",
        optionA: "Naughty text",
        optionB: "Sexy voice message",
        challengeA: "Write a naughty text now.",
        challengeB: "Pretend to send a sexy voice message."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a partner who is adventurous or traditional?",
        optionA: "Adventurous",
        optionB: "Traditional",
        challengeA: "Describe adventurous ideal.",
        challengeB: "Describe traditional ideal."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex outdoors or indoors?",
        optionA: "Outdoors",
        optionB: "Indoors",
        challengeA: "Describe outdoor location.",
        challengeB: "Describe indoor spot."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on your collarbone or on your back?",
        optionA: "Collarbone",
        optionB: "Back",
        challengeA: "Make collarbone kiss sound.",
        challengeB: "Make back kiss sound."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try spanking or being spanked?",
        optionA: "Try spanking",
        optionB: "Be spanked",
        challengeA: "Describe spanking style.",
        challengeB: "Describe feeling being spanked."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a risqué selfie or receive one?",
        optionA: "Send selfie",
        optionB: "Receive selfie",
        challengeA: "Describe your selfie pose.",
        challengeB: "Describe your reaction."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner wear sexy lingerie or nothing at all?",
        optionA: "Sexy lingerie",
        optionB: "Nothing at all",
        challengeA: "Describe their lingerie.",
        challengeB: "Describe how it feels."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper in your partner’s ear or kiss their neck?",
        optionA: "Whisper",
        optionB: "Kiss neck",
        challengeA: "Whisper a secret.",
        challengeB: "Describe neck kiss."
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
        text: "Would you rather try new positions or stick to your favorite?",
        optionA: "New positions",
        optionB: "Favorite position",
        challengeA: "Describe a position you want to try.",
        challengeB: "Describe your favorite position."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease with food or with toys?",
        optionA: "Food",
        optionB: "Toys",
        challengeA: "Describe food teasing.",
        challengeB: "Describe toy teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather kiss your partner’s hands or their lips first?",
        optionA: "Hands first",
        optionB: "Lips first",
        challengeA: "Describe kissing hands.",
        challengeB: "Describe kissing lips."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex on a couch or on a dining table?",
        optionA: "Couch",
        optionB: "Dining table",
        challengeA: "Describe couch scenario.",
        challengeB: "Describe dining table scenario."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner whisper sweet nothings or talk dirty during sex?",
        optionA: "Sweet nothings",
        optionB: "Dirty talk",
        challengeA: "Say a sweet nothing aloud.",
        challengeB: "Say a dirty line aloud."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tickled lightly or bitten softly?",
        optionA: "Tickled",
        optionB: "Bitten",
        challengeA: "Describe tickling sensation.",
        challengeB: "Describe biting sensation."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex with music playing or in complete silence?",
        optionA: "Music playing",
        optionB: "Silence",
        challengeA: "Describe your music playlist.",
        challengeB: "Describe why silence excites you."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tease with feather or silk scarf?",
        optionA: "Feather",
        optionB: "Silk scarf",
        challengeA: "Describe feather teasing.",
        challengeB: "Describe silk scarf teasing."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed on the stomach or the inner thigh?",
        optionA: "Stomach",
        optionB: "Inner thigh",
        challengeA: "Describe stomach kiss.",
        challengeB: "Describe inner thigh kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try temperature play with ice or wax?",
        optionA: "Ice",
        optionB: "Wax",
        challengeA: "Describe ice play.",
        challengeB: "Describe wax play."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be blindfolded during foreplay or during sex?",
        optionA: "During foreplay",
        optionB: "During sex",
        challengeA: "Describe blindfolded foreplay.",
        challengeB: "Describe blindfolded sex."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a naughty text or a sexy photo?",
        optionA: "Naughty text",
        optionB: "Sexy photo",
        challengeA: "Write a naughty text.",
        challengeB: "Describe the photo you'd send."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be teased by your partner or tease them back?",
        optionA: "Be teased",
        optionB: "Tease them",
        challengeA: "Describe how it feels to be teased.",
        challengeB: "Describe your teasing style."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be kissed passionately or gently?",
        optionA: "Passionately",
        optionB: "Gently",
        challengeA: "Describe passionate kiss.",
        challengeB: "Describe gentle kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have sex in a public place or in a private hideaway?",
        optionA: "Public place",
        optionB: "Private hideaway",
        challengeA: "Describe your public place fantasy.",
        challengeB: "Describe your private hideaway."
    ),
    Question(
        id: UUID(),
        text: "Would you rather your partner wear something sexy or nothing at all?",
        optionA: "Something sexy",
        optionB: "Nothing at all",
        challengeA: "Describe sexy outfit.",
        challengeB: "Describe how it feels."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a sexy game or watch an erotic movie together?",
        optionA: "Sexy game",
        optionB: "Erotic movie",
        challengeA: "Describe a sexy game idea.",
        challengeB: "Describe an erotic movie."
    )
])

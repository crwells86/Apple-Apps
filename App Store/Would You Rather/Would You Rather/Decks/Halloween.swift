import Foundation

let hauntedHearts = Deck(name: "Haunted Hearts", icon: "👻", questions: [
    Question(
        id: UUID(),
        text: "Would you rather cuddle through a haunted house or make out in a graveyard at midnight?",
        optionA: "Cuddle through the haunted house",
        optionB: "Make out in the graveyard at midnight",
        challengeA: "Hold each other for 60 seconds without breaking eye contact.",
        challengeB: "Share a slow kiss for 20 seconds."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner be a mysterious vampire or a mischievous witch for a night?",
        optionA: "Mysterious vampire",
        optionB: "Mischievous witch",
        challengeA: "Lean in and whisper a secret fantasy.",
        challengeB: "Cast a playful 'spell' and give a compliment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather explore a cursed attic together or stay alone in an eerie lighthouse?",
        optionA: "Explore the cursed attic",
        optionB: "Stay in the eerie lighthouse",
        challengeA: "Find an object and invent a spooky backstory about it.",
        challengeB: "Tell your partner one thing you'd like to try later tonight."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have candlelight dinner in a haunted mansion or a moonlit picnic in a foggy field?",
        optionA: "Candlelight in haunted mansion",
        optionB: "Moonlit picnic in fog",
        challengeA: "Feed each other one bite, eyes closed.",
        challengeB: "Whisper a memory that made you fall for them."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be followed by a friendly ghost that flirts with you or a shy werewolf that cuddles?",
        optionA: "Flirty friendly ghost",
        optionB: "Shy cuddly werewolf",
        challengeA: "Do an exaggerated flirtatious line in a spooky voice.",
        challengeB: "Give a reassuring hug for 30 seconds."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dress as elegantly undead or wildly wicked for Halloween?",
        optionA: "Elegantly undead",
        optionB: "Wildly wicked",
        challengeA: "Strike your best 'undead' pose for a photo.",
        challengeB: "Whisper a playful dare into their ear."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get a mysterious love note left on your pillow or a secret admirer knocking at midnight?",
        optionA: "Love note on pillow",
        optionB: "Midnight knock",
        challengeA: "Read the note aloud dramatically.",
        challengeB: "Share what you'd say if you answered the door."
    ),
    Question(
        id: UUID(),
        text: "Would you rather spend the night solving a spooky mystery together or creating scary stories by candlelight?",
        optionA: "Solve a spooky mystery",
        optionB: "Create scary stories",
        challengeA: "Make a brave declaration to protect them in the story.",
        challengeB: "Tell a twisty story that ends with a compliment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get lightly spooked by a jump scare or intensely spooked by eerie whispers?",
        optionA: "Jump scare",
        optionB: "Eerie whispers",
        challengeA: "Let your partner jump-scare you and then hug them.",
        challengeB: "Whisper a secret in their ear and make it sweet."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be bound by a harmless love potion or freed by a daring midnight kiss?",
        optionA: "Bound by love potion",
        optionB: "Freed by midnight kiss",
        challengeA: "Pretend you’re intoxicated by compliments for 30s.",
        challengeB: "Give a dramatic, slow 'freedom' kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dance with skeletons at a masquerade or tango with a phantom under moonlight?",
        optionA: "Dance with skeletons",
        optionB: "Tango with a phantom",
        challengeA: "Do a silly skeleton dance move together.",
        challengeB: "Lead a dramatic slow dance for 45 seconds."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a spooky secret from your past or a bold fantasy for the future?",
        optionA: "Spooky past secret",
        optionB: "Bold future fantasy",
        challengeA: "Tell the secret in hushed, theatrical tones.",
        challengeB: "Describe that fantasy in vivid detail (no explicitness)."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dared to whisper 'I want you' in front of friends or write it in a Halloween card?",
        optionA: "Whisper in front of friends",
        optionB: "Write in a Halloween card",
        challengeA: "Whisper the phrase and hold their gaze.",
        challengeB: "Write a mini love note and hand it over slowly."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get a spooky couple's portrait painted or a mysteriously romantic Polaroid?",
        optionA: "Spooky painted portrait",
        optionB: "Mysterious Polaroid",
        challengeA: "Pose dramatically as if in a gothic painting.",
        challengeB: "Take a playful Polaroid and kiss for the photo."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be trapped in a creepy maze together or ride a haunted carousel alone with your partner watching?",
        optionA: "Trapped in creepy maze together",
        optionB: "Ride haunted carousel solo while partner watches",
        challengeA: "Lead the way for 2 minutes and keep them close.",
        challengeB: "Wave theatrically at your partner and blow them a kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a slow 'witch's brew' cocktail or a dark chocolate dessert candlelit?",
        optionA: "Slow cocktail",
        optionB: "Dark chocolate dessert",
        challengeA: "Feed them a sip without using hands.",
        challengeB: "Feed them a bite and whisper why they’re irresistible."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner write your name in a magic book or carve it into a pumpkin?",
        optionA: "Write name in magic book",
        optionB: "Carve name into pumpkin",
        challengeA: "Create a short 'spell' including their name.",
        challengeB: "Carve a tiny heart and kiss the pumpkin together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather swap spooky childhood ghost stories or exchange your naughtiest Halloween memory?",
        optionA: "Spooky childhood stories",
        optionB: "Naughtiest Halloween memory",
        challengeA: "Tell your story in a whisper with dramatic pauses.",
        challengeB: "Describe the memory without explicit detail—then wink."
    ),
    Question(
        id: UUID(),
        text: "Would you rather serenade your partner in a haunted chapel or whisper sweet nothings in a corn maze?",
        optionA: "Serenade in haunted chapel",
        optionB: "Whisper in corn maze",
        challengeA: "Sing one romantic line softly.",
        challengeB: "Whisper a compliment while holding their hand."
    ),
    Question(
        id: UUID(),
        text: "Would you rather spend Halloween night as ghostly strangers or as a couple everyone recognizes?",
        optionA: "Ghostly strangers",
        optionB: "Recognizable couple",
        challengeA: "Act like strangers meeting for the first time for 60s.",
        challengeB: "Strike a couple pose and tell each other one why-you-love moment."
    ),
    Question(
        id: UUID(),
        text: "Would you rather swap scary masks for a slow reveal or exchange whispered confessions behind masks?",
        optionA: "Slow reveal",
        optionB: "Whisper behind masks",
        challengeA: "Take off your mask dramatically and smile.",
        challengeB: "Confess something sweet in a mysterious tone."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a séance to summon romance or carve secrets into a candle that you light together?",
        optionA: "Séance to summon romance",
        optionB: "Carve secrets into candle",
        challengeA: "Make one theatrical 'romance wish' out loud.",
        challengeB: "Light the candle together and share a secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be tempted by a haunted dessert or thrilled by a spooky surprise under the bed?",
        optionA: "Haunted dessert",
        optionB: "Spooky surprise under the bed",
        challengeA: "Feed each other a dessert bite slowly.",
        challengeB: "Retrieve the surprise and give them a playful prize."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner paint your face like a sugar skull or braid your hair into a witchy style?",
        optionA: "Sugar skull face paint",
        optionB: "Witchy braid",
        challengeA: "Hold still while they paint a cheek heart.",
        challengeB: "Let them braid and then run fingers through it."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper ghostly compliments or shout daring dares on Halloween night?",
        optionA: "Whisper ghostly compliments",
        optionB: "Shout daring dares",
        challengeA: "Whisper three compliments in a spooky voice.",
        challengeB: "Shout a playful dare and follow through."
    ),
    Question(
        id: UUID(),
        text: "Would you rather watch a horror movie curled up together or play truth-or-dare after midnight?",
        optionA: "Watch horror movie curled up",
        optionB: "Play truth-or-dare after midnight",
        challengeA: "Cuddle close during the scariest scene.",
        challengeB: "Ask one daring but kind question."
    ),
    Question(
        id: UUID(),
        text: "Would you rather sneak kisses behind tombstones or write secrets in mist on a window?",
        optionA: "Sneak kisses behind tombstones",
        optionB: "Write secrets on a misted window",
        challengeA: "Share three quick kisses in different spots.",
        challengeB: "Write 'kiss me' and trace it with your finger."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade a spooky nickname for the night or reveal the pet name you secretly want?",
        optionA: "Use spooky nickname",
        optionB: "Reveal desired pet name",
        challengeA: "Call each other that nickname for the next round.",
        challengeB: "Say the pet name slowly and end with a kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the hero who saves the night or the mischievous spirit who leads the fun?",
        optionA: "Hero who saves the night",
        optionB: "Mischievous spirit leading fun",
        challengeA: "Play protector for the next minute: protect them from 'scares'.",
        challengeB: "Lead a 30-second playful prank that's sweet."
    ),
    Question(
        id: UUID(),
        text: "Would you rather end the night with a secret handshake or a daring midnight promise?",
        optionA: "Secret handshake",
        optionB: "Daring midnight promise",
        challengeA: "Create a quick secret handshake together.",
        challengeB: "Make one playful promise and seal it with a hug."
    )
])

let wickedWhispers = Deck(name: "Wicked Whispers", icon: "🕯️", questions: [
    Question(
        id: UUID(),
        text: "Would you rather be whispered ghost stories in bed or read each other tarot readings by candlelight?",
        optionA: "Whisper ghost stories",
        optionB: "Read tarot by candlelight",
        challengeA: "Tell the spookiest line in a sultry whisper.",
        challengeB: "Reveal one card meaning about love."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade a seductive costume for a silly one or wear matching creepy couple outfits?",
        optionA: "Seductive vs silly costume",
        optionB: "Matching creepy couple outfits",
        challengeA: "Show off your costume pose for 20s.",
        challengeB: "Strike a synchronized spooky pose."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your crush turn into a charming phantom or a tender zombie for one night?",
        optionA: "Charming phantom",
        optionB: "Tender zombie",
        challengeA: "Deliver a playful phantom compliment.",
        challengeB: "Give a gentle forehead kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dared to leave a flirty note on a stranger's table or post a mysterious photo on social media?",
        optionA: "Leave flirty note",
        optionB: "Post mysterious photo",
        challengeA: "Write a flirty one-liner and show it aloud.",
        challengeB: "Take a moody selfie with a wink."
    ),
    Question(
        id: UUID(),
        text: "Would you rather receive a box of spooky surprises or find a handwritten map to a secret date?",
        optionA: "Box of spooky surprises",
        optionB: "Handwritten map to secret date",
        challengeA: "Open one imaginary surprise dramatically.",
        challengeB: "Describe where the map leads in detail."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be pursued by a playful phantom who kisses your hand or a moonlit ghoul who compliments your style?",
        optionA: "Phantom kisses hand",
        optionB: "Moonlit ghoul compliments style",
        challengeA: "Let them kiss your hand slowly.",
        challengeB: "Accept the compliment and smile seductively."
    ),
    Question(
        id: UUID(),
        text: "Would you rather swap Halloween dares for truth or lair in whispered secrets all night?",
        optionA: "Swap dares for truth",
        optionB: "Whisper secrets all night",
        challengeA: "Answer one truth honestly and warmly.",
        challengeB: "Whisper a secret that isn't too serious."
    ),
    Question(
        id: UUID(),
        text: "Would you rather ride in a creaky hearse or glide in a fog-draped carriage for date night?",
        optionA: "Ride creaky hearse",
        optionB: "Glide in fog-draped carriage",
        challengeA: "Pretend to be gloomy romantic for 30s.",
        challengeB: "Hold hands and share a dreamy thought."
    ),
    Question(
        id: UUID(),
        text: "Would you rather let your partner pick a spooky playlist or plan a chilling surprise midnight activity?",
        optionA: "Partner picks playlist",
        optionB: "Partner plans surprise",
        challengeA: "Slow-dance to the first song for 30s.",
        challengeB: "Guess the surprise and be pleasantly wrong."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wander a moonlit cemetery for secrets or sneak into an abandoned theater for a private show?",
        optionA: "Wander cemetery",
        optionB: "Sneak into theater",
        challengeA: "Recite a fictional epitaph for each other.",
        challengeB: "Perform a 20s dramatic scene together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a mysterious sensory game blindfolded or trade seductive dares under a blanket fort?",
        optionA: "Blindfold sensory game",
        optionB: "Dares under blanket fort",
        challengeA: "Identify a soft object while blindfolded.",
        challengeB: "Complete one flirty dare chosen by your partner."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the witch stirring the pot of romance or the ghost making mischief all evening?",
        optionA: "Witch stirring romance",
        optionB: "Ghost making mischief",
        challengeA: "Mix a pretend potion and describe its effects.",
        challengeB: "Sneak a playful tickle attack."
    ),
    Question(
        id: UUID(),
        text: "Would you rather exchange eerie love letters or dare each other to compliment a stranger in costume?",
        optionA: "Exchange love letters",
        optionB: "Compliment stranger in costume",
        challengeA: "Read one line from your letter dramatically.",
        challengeB: "Give one sincere compliment out loud."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a haunted portrait that winks at you or a jack-o'-lantern that whispers your name?",
        optionA: "Haunted portrait winks",
        optionB: "Jack-o'-lantern whispers name",
        challengeA: "Wink back and say a flirty line.",
        challengeB: "Respond to it like it's real with a kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dance in a cemetery fog or slow-sway in a moonlit cornfield?",
        optionA: "Dance in cemetery fog",
        optionB: "Slow-sway in cornfield",
        challengeA: "Hold each other and spin once.",
        challengeB: "Slowly recite one thing you adore about them."
    ),
    Question(
        id: UUID(),
        text: "Would you rather take a midnight swim in moonlit water or brave a late-night hayride with spooky stops?",
        optionA: "Midnight swim",
        optionB: "Late-night hayride",
        challengeA: "Describe the feeling of the water in a sultry tone.",
        challengeB: "Share a fun scare and then cuddle."
    ),
    Question(
        id: UUID(),
        text: "Would you rather exchange creepy pet names for the night or invent a ritual that brings you closer?",
        optionA: "Creepy pet names",
        optionB: "Invent closeness ritual",
        challengeA: "Use the pet name three times during the next round.",
        challengeB: "Perform the ritual with sincere eye contact."
    ),
    Question(
        id: UUID(),
        text: "Would you rather dress as a hauntingly beautiful ghost or a daring carnival barker for a party?",
        optionA: "Beautiful ghost",
        optionB: "Carnival barker",
        challengeA: "Float over and give a slow compliment.",
        challengeB: "Pitch a playful 'show' to your partner."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try a 'spirit kiss' where you kiss the air above someone's lips or whisper three wishes into their ear?",
        optionA: "Spirit kiss above lips",
        optionB: "Whisper three wishes",
        challengeA: "Perform the spirit kiss and smile mischievously.",
        challengeB: "Whisper the wishes close and affectionate."
    ),
    Question(
        id: UUID(),
        text: "Would you rather explore an abandoned greenhouse or find a hidden attic with secret letters?",
        optionA: "Abandoned greenhouse",
        optionB: "Hidden attic with letters",
        challengeA: "Describe a mysterious plant and name it for them.",
        challengeB: "Read a line from an imaginary letter aloud romantically."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be caught dancing alone at midnight or serenading outside your partner's window?",
        optionA: "Dance alone at midnight",
        optionB: "Serenade outside window",
        challengeA: "Do one silly dance move and invite them to join.",
        challengeB: "Sing or hum a line and end with a smile."
    ),
    Question(
        id: UUID(),
        text: "Would you rather take turns telling a spooky pickup line or daring each other to reenact a ghostly scene?",
        optionA: "Tell spooky pickup lines",
        optionB: "Reenact ghostly scene",
        challengeA: "Deliver your line with dramatic flair.",
        challengeB: "Act out a 20s scene that ends with a hug."
    ),
    Question(
        id: UUID(),
        text: "Would you rather watch someone else tell scary stories or be the center of your partner's haunting tale?",
        optionA: "Watch someone else tell stories",
        optionB: "Be center of partner's tale",
        challengeA: "React as if you're terrified then laugh.",
        challengeB: "Let them narrate one flattering fictional scene."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a moonlit promise sealed with a candy apple or with a slow forehead kiss?",
        optionA: "Sealed with candy apple",
        optionB: "Slow forehead kiss",
        challengeA: "Share a bite from the apple playfully.",
        challengeB: "Give a tender forehead kiss and hold them close."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play hide-and-seek in a dim manor or tell secrets in a closet lit by a single candle?",
        optionA: "Hide-and-seek in manor",
        optionB: "Secrets in candlelit closet",
        challengeA: "Find them quickly and give a victorious smooch.",
        challengeB: "Share a small, sincere secret by candlelight."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get a flirty fortune from a gypsy or make your own spooky fortune for your partner?",
        optionA: "Receive flirty fortune",
        optionB: "Make your own fortune",
        challengeA: "Recite the fortune dramatically and claim it.",
        challengeB: "Write a playful future prediction and reveal it softly."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper 'I dare you' in the dark or let your partner dare you and accept?",
        optionA: "Whisper 'I dare you'",
        optionB: "Let partner dare you",
        challengeA: "Whisper it seductively and wait for reaction.",
        challengeB: "Accept the dare with enthusiasm and follow through."
    ),
    Question(
        id: UUID(),
        text: "Would you rather spend the night plotting a romantic prank or creating a spooky serenade together?",
        optionA: "Plot romantic prank",
        optionB: "Create spooky serenade",
        challengeA: "Plan one harmless prank and describe it.",
        challengeB: "Sing two lines of your duet in unison."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner trace a spiderweb pattern on your arm or draw a tiny bat on your wrist?",
        optionA: "Trace spiderweb on arm",
        optionB: "Draw tiny bat on wrist",
        challengeA: "Close your eyes and enjoy the tracing.",
        challengeB: "Show the drawing and give them a kiss on the hand."
    )
])

let midnightMischief = Deck(name: "Midnight Mischief", icon: "🎃", questions: [
    Question(
        id: UUID(),
        text: "Would you rather dance under a harvest moon or sneak a midnight snack in a spooky kitchen?",
        optionA: "Dance under harvest moon",
        optionB: "Midnight snack in spooky kitchen",
        challengeA: "Dance close for 45 seconds with slow steps.",
        challengeB: "Share your favorite snack and feed each other one bite."
    ),
    Question(
        id: UUID(),
        text: "Would you rather swap daring Halloween truths or act out a lover-and-monster skit for a minute?",
        optionA: "Swap daring truths",
        optionB: "Act out lover-monster skit",
        challengeA: "Reveal one truth and smile afterward.",
        challengeB: "Perform the skit playfully and end with a kiss."
    ),
    Question(
        id: UUID(),
        text: "Would you rather get a secret admirer text full of creepy compliments or a handwritten charm under your pillow?",
        optionA: "Secret admirer text",
        optionB: "Handwritten charm under pillow",
        challengeA: "Read the 'text' aloud in a flirty voice.",
        challengeB: "Reveal the charm and explain why it's perfect."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be trapped with your partner in a storybook of haunts or live a one-night fairytale with a dark twist?",
        optionA: "Trapped in haunted storybook",
        optionB: "One-night dark fairytale",
        challengeA: "Narrate a page about your partner as hero.",
        challengeB: "Describe your fairytale kiss scene romantically."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a broomstick date or a coffin-shaped cabaret for two?",
        optionA: "Broomstick date",
        optionB: "Coffin-shaped cabaret",
        challengeA: "Pretend to fly and hold them close.",
        challengeB: "Perform a short, playful cabaret line together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the one to pull a playful prank or the one who gets successfully pranked?",
        optionA: "Pull the prank",
        optionB: "Get successfully pranked",
        challengeA: "Describe your prank in whisper-detail for suspense.",
        challengeB: "Laugh it off and give the prankster a playful reward."
    ),
    Question(
        id: UUID(),
        text: "Would you rather indulge in a spooky sensory blind-taste test or a creepy-cute costume reveal?",
        optionA: "Blind-taste test",
        optionB: "Costume reveal",
        challengeA: "Guess three tastes while blindfolded.",
        challengeB: "Reveal costume piece slowly and ask for opinion."
    ),
    Question(
        id: UUID(),
        text: "Would you rather leave red rose petals in a haunted hallway or carve a small love message inside a pumpkin?",
        optionA: "Rose petals in hallway",
        optionB: "Carve message in pumpkin",
        challengeA: "Scatter imaginary petals and lead them along them.",
        challengeB: "Carve a quick 'U + Me' and kiss the pumpkin."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be serenaded by bats or by a mysterious violinist in fog?",
        optionA: "Serenaded by bats",
        optionB: "Violinist in fog",
        challengeA: "Make a whimsical bat-noise duet together.",
        challengeB: "Hug and sway as if to the violin music."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade a spooky secret tattoo idea or get matching temporary Halloween symbols?",
        optionA: "Secret tattoo idea",
        optionB: "Matching temporary symbols",
        challengeA: "Describe your secret tattoo idea in one sentence.",
        challengeB: "Press palms together and trace the symbol once."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper a spooky compliment or shout a silly love declaration across a yard?",
        optionA: "Whisper spooky compliment",
        optionB: "Shout silly declaration",
        challengeA: "Whisper three adjectives you love about them.",
        challengeB: "Shout a goofy proclamation then laugh together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game of 'who's the phantom' where you swap secrets or a dare-roulette with Halloween tasks?",
        optionA: "Swap secrets as phantom",
        optionB: "Dare-roulette",
        challengeA: "Share a small, sweet secret with theatrical flair.",
        challengeB: "Spin an imaginary wheel and accept its dare."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be gifted a spooky perfume or a mysterious locket that opens to a tiny photo?",
        optionA: "Spooky perfume",
        optionB: "Mysterious locket",
        challengeA: "Spritz 'perfume' on your partner's wrist and kiss it.",
        challengeB: "Pretend to open the locket and reveal a love note."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a cobweb drape your doorway for dramatic effect or a line of tiny pumpkins leading to a surprise?",
        optionA: "Cobweb doorway",
        optionB: "Tiny pumpkin trail",
        challengeA: "Slowly push through cobweb and compliment their look.",
        challengeB: "Follow the pumpkin trail and give a small gift at the end."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper a love haiku in a haunted garden or draw your partner's portrait in moonlight?",
        optionA: "Whisper love haiku",
        optionB: "Draw portrait in moonlight",
        challengeA: "Recite a 3-line haiku softly and lingering.",
        challengeB: "Sketch a quick face and point out what you love."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dared to recreate a vintage horror movie kiss or to invent a new spooky kiss style?",
        optionA: "Recreate vintage horror kiss",
        optionB: "Invent a spooky kiss style",
        challengeA: "Reenact the kiss with theatrical drama.",
        challengeB: "Invent and demonstrate the new kiss playfully."
    ),
    Question(
        id: UUID(),
        text: "Would you rather pick a potion that makes you irresistible for an hour or a charm that reveals a secret desire?",
        optionA: "Irresistible potion",
        optionB: "Charm that reveals desire",
        challengeA: "Act confidently and flirt for 60s.",
        challengeB: "Share one desire that's intimate but respectful."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner surprise you with a spooky scavenger hunt or join you in making creepy cocktails?",
        optionA: "Spooky scavenger hunt",
        optionB: "Make creepy cocktails together",
        challengeA: "Solve one clue together in 90s.",
        challengeB: "Mix and taste one cocktail and toast."
    ),
    Question(
        id: UUID(),
        text: "Would you rather let the wind carry a love letter to your partner or hide a promise in a hollow tree?",
        optionA: "Wind-carry love letter",
        optionB: "Hide promise in hollow tree",
        challengeA: "Read the love letter aloud as if carried by wind.",
        challengeB: "Make a small promise and 'bury' it playfully."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear a ring of thorns (fake) for style or a delicate spider ring for flair?",
        optionA: "Ring of thorns",
        optionB: "Delicate spider ring",
        challengeA: "Put it on and call each other dramatic names.",
        challengeB: "Show the ring and twine fingers together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper into a seashell found in a pumpkin patch or leave a message in a bottle outside a haunted pier?",
        optionA: "Whisper into seashell in patch",
        optionB: "Message in bottle at pier",
        challengeA: "Whisper a short wish then seal it with a kiss.",
        challengeB: "Pretend to throw the bottle and make a wish together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be the one who tells the last spooky tale of the night or the one who receives the final kiss?",
        optionA: "Tell last spooky tale",
        optionB: "Receive final kiss",
        challengeA: "Tell a short closing tale that ends with hope.",
        challengeB: "Accept the kiss and describe how it felt in one word."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade playful scares for compliments or trade costumes for a slow strip of accessories?",
        optionA: "Trade scares for compliments",
        optionB: "Strip accessories slowly",
        challengeA: "Give three heartfelt compliments after a playful scare.",
        challengeB: "Remove one accessory theatrically and smile."
    ),
    Question(
        id: UUID(),
        text: "Would you rather leave the room whispering 'remember this night' or paint each other's faces with glow-in-dark paint?",
        optionA: "Whisper 'remember this night'",
        optionB: "Paint faces with glow paint",
        challengeA: "Whisper the line close to their ear.",
        challengeB: "Paint a tiny heart and show it off."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dared to tell a naughty-but-kind ghost story or make a pact of mischief and kisses?",
        optionA: "Tell naughty-but-kind ghost story",
        optionB: "Make pact of mischief and kisses",
        challengeA: "Tell the story with playful blushing.",
        challengeB: "Seal the pact with a promise and a peck."
    ),
    Question(
        id: UUID(),
        text: "Would you rather decorate a haunted gingerbread house together or whisper secrets behind a candy corn curtain?",
        optionA: "Decorate haunted gingerbread",
        optionB: "Whisper behind candy corn curtain",
        challengeA: "Place one candy deliberately and name it for them.",
        challengeB: "Share a sweet secret and giggle together."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a tiny sparkler celebration at midnight or let a paper lantern drift with a wish?",
        optionA: "Tiny sparkler celebration",
        optionB: "Paper lantern with wish",
        challengeA: "Light a pretend sparkler and cheer softly.",
        challengeB: "Make a wish aloud and hug for 10s."
    ),
    Question(
        id: UUID(),
        text: "Would you rather adopt a spooky pet for the night (fake) or hold a séance to ask it a question?",
        optionA: "Adopt spooky pet",
        optionB: "Hold séance to ask it",
        challengeA: "Name the pet and act as its owner playfully.",
        challengeB: "Ask the pet one question and answer as it might."
    )
])

let graveyardGames = Deck(name: "Graveyard Games", icon: "🦇", questions: [
    Question(
        id: UUID(),
        text: "Would you rather sneak a kiss in a moonlit mausoleum or leave each other playful notes on headstones?",
        optionA: "Kiss in moonlit mausoleum",
        optionB: "Leave playful notes on headstones",
        challengeA: "Share a brief, tender kiss then hold hands.",
        challengeB: "Write a funny note and read it aloud."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trace spooky constellations on each other's skin or tie a ribbon with a secret wish?",
        optionA: "Trace constellations on skin",
        optionB: "Tie ribbon with secret wish",
        challengeA: "Draw one tiny star and name it after them.",
        challengeB: "Tie ribbon and whisper the wish into their ear."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game of 'who can be braver' in a dark hallway or swap daring dares in whispers?",
        optionA: "Be braver in dark hallway",
        optionB: "Swap daring dares in whispers",
        challengeA: "Walk the hallway together holding hands boldly.",
        challengeB: "Whisper a dare and accept one immediately."
    ),
    Question(
        id: UUID(),
        text: "Would you rather slowdance among cryptic statues or build a pillow tomb you both crawl into?",
        optionA: "Slowdance among statues",
        optionB: "Build pillow tomb together",
        challengeA: "Dance and sway as if nobody's watching.",
        challengeB: "Crawl in and share a conspiratorial giggle."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner read you a haunting poem or hum a mysterious tune all night?",
        optionA: "Read haunting poem",
        optionB: "Hum mysterious tune",
        challengeA: "Close your eyes and savor each line.",
        challengeB: "Lean in and hum along softly."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be dared to leave 'kiss marks' on a pumpkin or to plant a fake love token in a garden?",
        optionA: "Leave kiss marks on pumpkin",
        optionB: "Plant fake love token in garden",
        challengeA: "Plant a quick kiss on the pumpkin cheek.",
        challengeB: "Hide the token and describe where it's hidden."
    ),
    Question(
        id: UUID(),
        text: "Would you rather swap playful costumes then pick one outfit to keep for a romantic scene or keep your own and roleplay?",
        optionA: "Swap costumes and keep one",
        optionB: "Keep own and roleplay",
        challengeA: "Model the costume you kept with a dramatic pose.",
        challengeB: "Roleplay a short scene and end in a hug."
    ),
    Question(
        id: UUID(),
        text: "Would you rather tell your partner a secret that gives them shivers or ask them a question that makes them blush?",
        optionA: "Give them a shivery secret",
        optionB: "Ask a blush-inducing question",
        challengeA: "Deliver the secret in a low voice and smile.",
        challengeB: "Ask the question and wait for their reaction patiently."
    ),
    Question(
        id: UUID(),
        text: "Would you rather wear matching black gloves for a night of mystery or swap one hat that becomes your token?",
        optionA: "Matching black gloves",
        optionB: "Swap one token hat",
        challengeA: "Touch each other's gloved fingers slowly.",
        challengeB: "Wear the hat and tell a charming secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather send a mysterious voice message or craft a tiny scroll with a romantic riddle?",
        optionA: "Send mysterious voice message",
        optionB: "Craft scroll with riddle",
        challengeA: "Record a flirty line in a hushed tone.",
        challengeB: "Write a riddle whose answer is your partner."
    ),
    Question(
        id: UUID(),
        text: "Would you rather sneak a slow kiss under a gargoyle or tie your voices together in a duet under the stars?",
        optionA: "Kiss under a gargoyle",
        optionB: "Duet under the stars",
        challengeA: "Lean in and kiss for a memorable 10s.",
        challengeB: "Sing two lines and end with a shared smile."
    ),
    Question(
        id: UUID(),
        text: "Would you rather risk a playful dare from a trickster or offer a gentle truth from the heart?",
        optionA: "Accept trickster's dare",
        optionB: "Offer gentle truth",
        challengeA: "Complete the dare with dramatic flair.",
        challengeB: "Share a heartfelt truth and hold hands afterward."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade flirtatious postcards in a lantern-lit alley or carve secret initials out of chalk on a garden wall?",
        optionA: "Trade postcards in alley",
        optionB: "Chalk initials on garden wall",
        challengeA: "Read your postcard aloud like a lover.",
        challengeB: "Trace the initials together and make a wish."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper a single forbidden word to each other or invent a harmless spell that binds you to smiles?",
        optionA: "Whisper forbidden word",
        optionB: "Invent smile-binding spell",
        challengeA: "Whisper the word softly and then laugh together.",
        challengeB: "Perform the tiny spell and grin widely."
    ),
    Question(
        id: UUID(),
        text: "Would you rather be given a tiny jar of 'courage' or a vial of 'mystery' to share for the night?",
        optionA: "Jar of courage",
        optionB: "Vial of mystery",
        challengeA: "Take an imaginary sip and act braver for a minute.",
        challengeB: "Pretend to uncork mystery and tell a secret."
    ),
    Question(
        id: UUID(),
        text: "Would you rather whisper compliments with a fake accent or use only movie lines to flirt for an hour?",
        optionA: "Compliments with fake accent",
        optionB: "Flirt using movie lines",
        challengeA: "Speak a compliment in your best accent.",
        challengeB: "Deliver one classic line and add a wink."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a game where you both reveal a single guilty pleasure or perform a dramatic slow-motion escape together?",
        optionA: "Reveal guilty pleasure",
        optionB: "Slow-motion escape act",
        challengeA: "Confess your guilty pleasure lightly and honestly.",
        challengeB: "Stage a fun slow-motion escape and laugh."
    ),
    Question(
        id: UUID(),
        text: "Would you rather try to summon a cheeky spirit that offers compliments or a quiet one that grants cuddles?",
        optionA: "Cheeky spirit with compliments",
        optionB: "Quiet spirit that grants cuddles",
        challengeA: "Let the 'spirit' give three compliments to your partner.",
        challengeB: "Cuddle for 60 seconds like the spirit insisted."
    ),
    Question(
        id: UUID(),
        text: "Would you rather plan a secret midnight picnic inside a crypt or map a route of tiny surprises around the house?",
        optionA: "Midnight picnic in crypt",
        optionB: "Route of tiny surprises",
        challengeA: "Describe your ideal midnight picnic menu seductively.",
        challengeB: "Hide one small surprise now and give a hint."
    ),
    Question(
        id: UUID(),
        text: "Would you rather leave a trail of glittering confetti for your partner to find or a ribbon with a note tied to it?",
        optionA: "Glittering confetti trail",
        optionB: "Ribbon with note",
        challengeA: "Pretend to follow the trail and 'discover' them.",
        challengeB: "Unravel the ribbon and read the note aloud."
    ),
    Question(
        id: UUID(),
        text: "Would you rather share a whispered dare that involves tickles or one that involves a secret compliment?",
        optionA: "Dare with tickles",
        optionB: "Dare with secret compliment",
        challengeA: "Deliver a soft tickle and hold them close.",
        challengeB: "Share the secret compliment with a warm smile."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have a lantern that reveals hidden messages or a mirror that reflects a future date night?",
        optionA: "Lantern revealing messages",
        optionB: "Mirror reflecting future date",
        challengeA: "Look into the lantern's glow and say one message.",
        challengeB: "Describe the future date you see in one sentence."
    ),
    Question(
        id: UUID(),
        text: "Would you rather slip a single rose petal into your partner's shoe or tuck a tiny parchment into their pocket?",
        optionA: "Rose petal in shoe",
        optionB: "Parchment in pocket",
        challengeA: "Place the imaginary petal and watch their reaction.",
        challengeB: "Read the parchment aloud in a playful tone."
    ),
    Question(
        id: UUID(),
        text: "Would you rather play a shadow-puppet story that reveals a secret or make shadow silhouettes of each other and name them?",
        optionA: "Shadow-puppet secret story",
        optionB: "Make and name shadow silhouettes",
        challengeA: "Perform a short puppet story with a romantic twist.",
        challengeB: "Create and name a silhouette after someone you adore."
    ),
    Question(
        id: UUID(),
        text: "Would you rather invent a graveyard handshake or leave a tiny lantern by your partner's doorstep each night?",
        optionA: "Invent graveyard handshake",
        optionB: "Leave tiny lantern nightly",
        challengeA: "Create the handshake and perform it now.",
        challengeB: "Pretend to set a lantern and make a wish for them."
    ),
    Question(
        id: UUID(),
        text: "Would you rather have your partner braid a charm into your hair or tuck a tiny poem into your collar?",
        optionA: "Braid charm into hair",
        optionB: "Tuck poem into collar",
        challengeA: "Let them braid and smile while they do it.",
        challengeB: "Read the poem and give a grateful kiss on the cheek."
    ),
    Question(
        id: UUID(),
        text: "Would you rather trade one sincere 'I like that about you' for a spooky prank or accept both and share a last slow dance?",
        optionA: "Sincere compliment for prank",
        optionB: "Accept both and slow dance",
        challengeA: "Deliver the compliment earnestly, then proceed with the prank.",
        challengeB: "Slow-dance for one minute and end with a cheerful spin."
    )
])

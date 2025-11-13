import Foundation

let thanksgivingSpice = Deck(name: "Thanksgiving Spice", icon: "🦃", questions: [
    Question(id: UUID(), text: "Would you rather have Thanksgiving dinner in bed or dessert in the shower?", optionA: "Dinner in bed", optionB: "Dessert in the shower", challengeA: "Feed your partner something sweet", challengeB: "Whisper your favorite treat in their ear"),
    
    Question(id: UUID(), text: "Would you rather share a pumpkin pie or a cozy blanket with your partner?", optionA: "Pumpkin pie", optionB: "Cozy blanket", challengeA: "Feed each other a bite", challengeB: "Snuggle for 2 minutes without talking"),
    
    Question(id: UUID(), text: "Would you rather play footsie under the Thanksgiving table or sneak a kiss in the kitchen?", optionA: "Footsie under the table", optionB: "Kiss in the kitchen", challengeA: "Hold hands for the next question", challengeB: "Give your partner a quick peck"),
    
    Question(id: UUID(), text: "Would you rather get caught flirting with your partner or feeding them turkey?", optionA: "Flirting", optionB: "Feeding turkey", challengeA: "Compliment your partner’s best feature", challengeB: "Feed them something nearby"),
    
    Question(id: UUID(), text: "Would you rather make your own ‘thankful’ list about your partner or have them make one about you?", optionA: "Make one about them", optionB: "Have them make one", challengeA: "Say one thing you love about them", challengeB: "Let them say one thing they love about you"),
    
    Question(id: UUID(), text: "Would you rather wear nothing but a pilgrim hat or a turkey apron?", optionA: "Pilgrim hat", optionB: "Turkey apron", challengeA: "Do your best ‘thankful’ pose", challengeB: "Strike a fun chef pose"),
    
    Question(id: UUID(), text: "Would you rather cook Thanksgiving dinner together or order takeout and focus on dessert?", optionA: "Cook together", optionB: "Takeout & dessert", challengeA: "Pretend to stir something while dancing", challengeB: "Feed your partner a bite of something sweet"),
    
    Question(id: UUID(), text: "Would you rather go on a romantic fall walk or cuddle up to a Thanksgiving movie?", optionA: "Fall walk", optionB: "Cuddle movie", challengeA: "Describe your perfect fall date", challengeB: "Cuddle through the next round"),
    
    Question(id: UUID(), text: "Would you rather carve the turkey or carve out some alone time?", optionA: "Carve the turkey", optionB: "Alone time", challengeA: "Do your best chef impression", challengeB: "Share one secret you’ve never told anyone"),
    
    Question(id: UUID(), text: "Would you rather share a slice of pie or a cozy blanket right now?", optionA: "Slice of pie", optionB: "Cozy blanket", challengeA: "Feed them an imaginary bite", challengeB: "Give them a warm hug"),
    
    Question(id: UUID(), text: "Would you rather play ‘Truth or Turkey’ or ‘Spin the Pumpkin’?", optionA: "Truth or Turkey", optionB: "Spin the Pumpkin", challengeA: "Answer one fun truth from your partner", challengeB: "Let your partner give you a mini dare"),
    
    Question(id: UUID(), text: "Would you rather have your partner whisper what they’re thankful for about you, or show you?", optionA: "Whisper", optionB: "Show", challengeA: "Whisper something you love about them", challengeB: "Show affection however you want"),
    
    Question(id: UUID(), text: "Would you rather play sous-chef for your partner or be the head chef?", optionA: "Sous-chef", optionB: "Head chef", challengeA: "Pretend to follow their cooking orders", challengeB: "Give one playful command"),
    
    Question(id: UUID(), text: "Would you rather start a food fight or a flirt fight?", optionA: "Food fight", optionB: "Flirt fight", challengeA: "Toss a pretend cranberry", challengeB: "Flirt for 30 seconds straight"),
    
    Question(id: UUID(), text: "Would you rather have dinner by candlelight or dessert by firelight?", optionA: "Dinner by candlelight", optionB: "Dessert by firelight", challengeA: "Describe your ideal candlelit dinner", challengeB: "Describe your favorite cozy dessert moment"),
    
    Question(id: UUID(), text: "Would you rather your partner feed you mashed potatoes or whipped cream?", optionA: "Mashed potatoes", optionB: "Whipped cream", challengeA: "Feed each other a pretend spoonful", challengeB: "Pretend to feed each other dessert"),
    
    Question(id: UUID(), text: "Would you rather be each other’s Thanksgiving dessert or after-dinner entertainment?", optionA: "Dessert", optionB: "Entertainment", challengeA: "Say your sweetest compliment", challengeB: "Do your funniest dance move"),
    
    Question(id: UUID(), text: "Would you rather have a slow dance in the kitchen or a cuddle on the couch after dinner?", optionA: "Slow dance", optionB: "Cuddle", challengeA: "Dance for 30 seconds", challengeB: "Hold your partner for 30 seconds"),
    
    Question(id: UUID(), text: "Would you rather give your partner a back rub or get one?", optionA: "Give one", optionB: "Get one", challengeA: "Give a 30-second back rub", challengeB: "Accept it graciously 😉"),
    
    Question(id: UUID(), text: "Would you rather go around saying what you’re thankful for—or show it with a kiss?", optionA: "Say it", optionB: "Show it", challengeA: "Say something you’re thankful for", challengeB: "Give a quick kiss"),
    
    Question(id: UUID(), text: "Would you rather watch football together or make your own post-dinner game?", optionA: "Watch football", optionB: "Make a game", challengeA: "Predict who wins the game", challengeB: "Invent a 30-second challenge"),
    
    Question(id: UUID(), text: "Would you rather help clean up the kitchen or convince your partner to skip it?", optionA: "Clean up", optionB: "Skip it", challengeA: "Do a playful cleaning dance", challengeB: "Find a creative reason to skip it"),
    
    Question(id: UUID(), text: "Would you rather host Friendsgiving or escape for a romantic Thanksgiving getaway?", optionA: "Friendsgiving", optionB: "Romantic getaway", challengeA: "Say who you’d invite", challengeB: "Describe your dream getaway"),
    
    Question(id: UUID(), text: "Would you rather play a round of ‘Who’s Most Likely To’ or another spicy ‘Would You Rather’?", optionA: "Who’s Most Likely To", optionB: "Would You Rather", challengeA: "Ask your partner a fun ‘Most Likely’ question", challengeB: "Ask a bonus spicy ‘Would You Rather’"),
    
    Question(id: UUID(), text: "Would you rather have leftovers in bed or breakfast in bed the next morning?", optionA: "Leftovers in bed", optionB: "Breakfast in bed", challengeA: "Describe your dream midnight snack", challengeB: "Describe your perfect morning together")
])

let flirtyFeast = Deck(name: "Flirty Feast", icon: "🍷", questions: [

    Question(id: UUID(), text: "Would you rather be called ‘saucy’ or ‘stuffed’ by everyone here tonight?", optionA: "Saucy", optionB: "Stuffed", challengeA: "Say your flirtiest Thanksgiving pun", challengeB: "Give your best ‘I’m full’ face"),

    Question(id: UUID(), text: "Would you rather be the main course or the irresistible dessert?", optionA: "Main course", optionB: "Dessert", challengeA: "Describe yourself as a dish", challengeB: "Describe your ‘sweetest’ quality"),

    Question(id: UUID(), text: "Would you rather share your seat or steal someone’s?", optionA: "Share", optionB: "Steal", challengeA: "Invite someone to share your seat for one round", challengeB: "Sit in someone else’s spot for one turn"),

    Question(id: UUID(), text: "Would you rather play footsie under the table or lock eyes across it?", optionA: "Footsie", optionB: "Eye contact", challengeA: "Tap someone’s foot gently under the table", challengeB: "Hold eye contact for 10 seconds"),

    Question(id: UUID(), text: "Would you rather be described as ‘too hot to handle’ or ‘too sweet to resist’?", optionA: "Too hot to handle", optionB: "Too sweet to resist", challengeA: "Strike your hottest pose", challengeB: "Say something irresistibly charming"),

    Question(id: UUID(), text: "Would you rather play Truth or Turkey or Dare and Dessert?", optionA: "Truth or Turkey", optionB: "Dare and Dessert", challengeA: "Answer a playful truth from the group", challengeB: "Accept a lighthearted dare"),

    Question(id: UUID(), text: "Would you rather whisper something thankful into someone’s ear or have someone whisper it to you?", optionA: "Whisper it", optionB: "Receive it", challengeA: "Whisper one compliment to anyone", challengeB: "Let someone whisper one to you"),

    Question(id: UUID(), text: "Would you rather feed someone a bite of pie or be fed a bite?", optionA: "Feed someone", optionB: "Be fed", challengeA: "Pretend to feed someone a dessert", challengeB: "Pretend to enjoy being fed"),

    Question(id: UUID(), text: "Would you rather give a compliment that makes someone blush or take one that makes you blush?", optionA: "Give one", optionB: "Take one", challengeA: "Compliment someone boldly", challengeB: "Accept a compliment with your best reaction"),

    Question(id: UUID(), text: "Would you rather win ‘Flirt of the Feast’ or ‘Charm of the Table’?", optionA: "Flirt of the Feast", optionB: "Charm of the Table", challengeA: "Show your flirty side for 15 seconds", challengeB: "Say something smooth and confident"),

    Question(id: UUID(), text: "Would you rather your nickname tonight be ‘Pumpkin Spice’ or ‘Hot Gravy’?", optionA: "Pumpkin Spice", optionB: "Hot Gravy", challengeA: "Own the nickname for two rounds", challengeB: "Introduce yourself to the group with it"),

    Question(id: UUID(), text: "Would you rather playfully tease someone at the table or be the one teased?", optionA: "Tease someone", optionB: "Be teased", challengeA: "Give a playful tease", challengeB: "Take it and blush"),

    Question(id: UUID(), text: "Would you rather be dared to flirt or dared to dance?", optionA: "Flirt", optionB: "Dance", challengeA: "Flirt for 10 seconds with someone", challengeB: "Do your best ‘flirty’ dance move"),

    Question(id: UUID(), text: "Would you rather your partner get a little jealous or a little flirty tonight?", optionA: "Jealous", optionB: "Flirty", challengeA: "Say what would make them jealous", challengeB: "Show how they’d flirt back"),

    Question(id: UUID(), text: "Would you rather lose a round and give a compliment or win and take one?", optionA: "Give a compliment", optionB: "Take one", challengeA: "Compliment whoever’s to your left", challengeB: "Receive one without breaking eye contact"),

    Question(id: UUID(), text: "Would you rather play ‘Guess the Flavor’ blindfolded or ‘Guess Who Said It’?", optionA: "Guess the Flavor", optionB: "Guess Who Said It", challengeA: "Close your eyes for one round", challengeB: "Guess who gave a compliment earlier"),

    Question(id: UUID(), text: "Would you rather accidentally flirt with a friend’s date or your boss at the Thanksgiving party?", optionA: "Friend’s date", optionB: "Boss", challengeA: "Tell your funniest flirt fail", challengeB: "Make up a fake one"),

    Question(id: UUID(), text: "Would you rather be the first to start a dance-off or the last to stop it?", optionA: "First to start", optionB: "Last to stop", challengeA: "Start a short dance", challengeB: "Keep dancing until someone joins"),

    Question(id: UUID(), text: "Would you rather playfully roast someone or make them blush?", optionA: "Roast them", optionB: "Make them blush", challengeA: "Give a flirty roast", challengeB: "Say something that’ll get a blush"),

    Question(id: UUID(), text: "Would you rather flirt using Thanksgiving food names or only using movie quotes?", optionA: "Food names", optionB: "Movie quotes", challengeA: "Do one of each", challengeB: "Let the group vote on the best one"),

    Question(id: UUID(), text: "Would you rather have to wink every time someone says ‘turkey’ or blow a kiss every time someone says ‘pie’?", optionA: "Wink on ‘turkey’", optionB: "Kiss on ‘pie’", challengeA: "Do your best wink", challengeB: "Give a dramatic air kiss"),

    Question(id: UUID(), text: "Would you rather have everyone share their funniest flirt attempt or most awkward holiday moment?", optionA: "Funniest flirt attempt", optionB: "Awkward holiday moment", challengeA: "Share yours", challengeB: "Pass and take a sip"),

    Question(id: UUID(), text: "Would you rather play ‘Name That Compliment’ or ‘Finish That Flirt’?", optionA: "Name That Compliment", optionB: "Finish That Flirt", challengeA: "Give someone a quick compliment", challengeB: "Finish someone else’s flirt line"),

    Question(id: UUID(), text: "Would you rather your next compliment be whispered or shouted?", optionA: "Whispered", optionB: "Shouted", challengeA: "Whisper a flirty line to anyone", challengeB: "Shout a compliment dramatically"),

    Question(id: UUID(), text: "Would you rather have your next dare be sweet or spicy?", optionA: "Sweet", optionB: "Spicy", challengeA: "Give someone a heartwarming compliment", challengeB: "Give someone a daring compliment")
])


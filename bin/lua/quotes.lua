require "core:core"
core.declare("quotes")
core.declare("quote_count")

quotes = {
	{ author = 'Guts',      text = "\"Even though I know it's safe here, without my sword, I cannot sleep.\"" },
	{ author = 'Guts',      text = "\"Look around you carefully. Strain your eyes at the darkness around us... At the darkness around me.\"" },
	{ author = 'Guts',      text = "\"If you follow me to this place, the entire world... is a battlefield.\"" },
	{ author = 'Guts',      text = "\"Humans are weak... but we want to live... even if we're wounded... or tortured... we feel the pain...\"" },
	{ author = 'Guts',      text = "\"Is this place going to be your grave? Is this really how you want to die? Every sword belongs in its sheath. Go back to the holder of that sheath.\"" },
	{ author = 'Guts',      text = "\"This fight... it is far from over. We are the generals. Protect her while I attack. I am the raiding party, I will destroy the enemy camp.\"" },
	{ author = 'Guts',      text = "\"This place is the last you'll ever see. Your deaths mean nothing to me.\"" },
	{ author = 'Guts',      text = "\"My place really was here. I was too foolish and stubborn to notice. But, what I truly hoped for then was here... Why do I always realize it.. When I've already lost it...\"" },
	{ author = 'Guts',      text = "\"If you're always worried about crushing the ants beneath you...you won't be able to walk.\"" },
	{ author = 'Guts',      text = "\"When you meet your God tell him to leave me alone.\"" },
	{ author = 'Guts',      text = "\"Let's go drink. Didn't you know? Alcohol can cure poison.\"" },
	{ author = 'Guts',      text = "\"Do whatever you want now. But if you disturb me, I'll kill you.\"" },
	{ author = 'Guts',      text = "\"I've never expected a miracle. I will get things done myself.\"" },
	{ author = 'Guts',      text = "\"DO NOT PRAY! If you pray, your hands will close together. You will not be able to fight!\"" },
	{ author = 'Guts',      text = "\"He appeared right in front of me, and he wasn't a demon... but what looked like a human. As if he'd been yanked from before into the present unchanged. I gazed at him and for a second... I forgot to kill him.\"" },
	{ author = 'Griffith',  text = "\"Now, he's happy. Or, is death the end of the dream? Is it a failure of hope?\"" },
	{ author = 'Griffith',  text = "\"I always get what I want.\"" },
	{ author = 'Griffith',  text = "\"Among thousands of comrades and ten thousand enemies, only you... only you made me forget my dream.\"" },
	{ author = 'Griffith',  text = "\"A dream... It's something you do for yourself, not for others.\"" },
	{ author = 'Griffith',  text = "\"A friend would not just follow another's dream... a friend would find his own reason to live...\"" },
	{ author = 'Godo',      text = "\"Hate is a place where a man who can't stand sadness goes.\"" },
	{ author = 'Godo',      text = "\"If you desire one thing for so long, it's a given that you'll miss other things along the way. That's how it is... that's life.\"" },
	{ author = 'Godo',      text = "\"It was called the dragon because no human hands could wield it.\"" },
	{ author = 'Godo',      text = "\"Hate is a place where a man who can't stand sadness goes.\""},
}

quote_count = #quotes
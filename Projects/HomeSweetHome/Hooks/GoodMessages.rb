
module Hooks
	module Positivity
		@messageClient = Messaging::UserClient.new($mqtt, "Xasin", "NiceMessage");

		@messages = [
			"Remember: Productivity is not the goal. It's enjoying what you do!",
			"Hey, how about you take a small break and reflect what you're doing?",
			"Are you stuck on a task? Maybe you should give yourself a breather, and then do something else!",
			"I hope you're feeling good, because ... Well, you should!",
			"If your plans aren't working out ... That's ok. You have all the time you need - you can work on them later :)",
			"I hope you're enjoying what you are doing - you deserve to :)",
			"You're awesome and you should relax!",
			"Remember that the passion to do something does not come from willpower alone. Breed it, let it go by feeling confident, feeling good about yourself - then your passions will soon after follow <3",
			"When you feel like you *need* to do something ... Remember, you have time.
			 The most important thing is you, first and foremost, and ... Let projects come naturally, when you enjoy them.",
			"Do you want to switch to something different, try something out? If you feel like it, maybe now's a good time to do so!
			 But remember, there is no need to rush or feel obligated :)",
			"Don't forget to balance out your productivity with some lighthearted relaxing!",
		]

		@nextMessage = Time.now();
		Thread.new do
			loop do
				sleep [1.minutes, (@nextMessage - Time.now()).to_i].max until @nextMessage < Time.now();
				@nextMessage = Time.now() + rand(60..120).minutes;

				next unless (Time.now().hour).between?(7,22) and $xasin.awake?
				@messageClient.speak @messages.sample, Color.RGB(150, 255, 150);
			end
		end
	end
end

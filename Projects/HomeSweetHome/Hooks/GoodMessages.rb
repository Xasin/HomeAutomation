
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
		]

		@nextMessage = Time.now();
		Thread.new do
			loop do
				sleep [1.minutes, (@nextMessage - Time.now()).to_i].max until @nextMessage < Time.now();
				@nextMessage = Time.now() + rand(45..120).minutes;

				next unless (Time.now().hour).between?(9,23);
				@messageClient.speak @messages.sample, Color.RGB(150, 255, 150);
			end
		end
	end
end

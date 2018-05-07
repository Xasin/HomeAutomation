
require_relative "test_setup.rb"

require "test/unit/runner/gtk2"
require 'test/unit'
class TestAutomaticLights < Test::Unit::TestCase
	def test_light_thresholds
		$xasin.home = true;
		$xasin.switch = "Xasin";
		$room.lights = false;
		$mqtt.publish_to "Room/default/Sensors/Brightness", 65000
		sleep 1;

		$mqtt.publish_to "Room/default/Sensors/Brightness", 0
		sleep 1;
		assert $room.lightSwitch, "Lights didn't turn on!"

		$mqtt.publish_to "Room/default/Sensors/Brightness", 225
		sleep 1;
		assert $room.lightSwitch, "Lights didn't stay on!"

		$mqtt.publish_to "Room/default/Sensors/Brightness", 65000
		sleep 1;
		assert (not $room.lightSwitch), "Lights didn't turn off!"

		$mqtt.publish_to "Room/default/Sensors/Brightness", 225
		sleep 1
		assert (not $room.lightSwitch), "Lights didn't stay off!"
	end

	def test_xasin_away_status
		$xasin.switch = "Xasin";
		$xasin.home = true;
		$mqtt.publish_to "Room/default/Sensors/Brightness", 0
		$room.lights = true;
		sleep 1;

		$xasin.home = false;
		sleep 1;
		assert (not $room.lightSwitch), "Lights didn't switch off."

		sleep 0.5
		$xasin.home = true;
		sleep 1;
		assert $room.lightSwitch, "Lights didn't switch back on."

		$mqtt.publish_to "Room/default/Sensors/Brightness", 65000
		$xasin.home = false;
		sleep 1;
		$xasin.home = true;
		sleep 1;
		assert (not $room.lightSwitch), "Lights didn't stay off."
	end

	def test_xasin_awake_status
		$xasin.switch = "Xasin";
		$xasin.home = true;
		$mqtt.publish_to "Room/default/Sensors/Brightness", 0
		$room.lights = true;
		sleep 1;

		$xasin.switch = "none";
		sleep 1;
		assert (not $room.lightSwitch), "Lights didn't switch off."

		$xasin.switch = "Xasin";
		sleep 1;
		assert ($room.lightSwitch), "Lights didn't switch on."

		$xasin.switch = "none";
		$mqtt.publish_to "Room/default/Sensors/Brightness", 65000
		sleep 0.5
		$xasin.switch = "Xasin";
		sleep 1
		assert (not $room.lightSwitch), "Lights didn't stay off."
	end
end

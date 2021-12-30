s.boot;

y = {SinOsc.ar(440, 0, 0.03)!2}.play;
y.free;

MIDIClient.init;
MIDIIn.connectAll;

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	{
		var sig, env;
		sig = SinOsc.ar(nn.midicps)!2;
		env = EnvGen.kr(Env.perc, doneAction:2);
		env = sig * env * vel.linexp(1,127,0.01,0.5);
	}.play;
});
)
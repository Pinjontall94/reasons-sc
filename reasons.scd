s.boot; // start sound server
s.quit; //kill sound server;

// Initialize monitors
(
s.meter;
s.plotTree;
s.scope;
)

// MIDI Stuff

MIDIIn.connectAll;
MIDIIn.disconnectAll;
MIDIFunc.trace(true);
MIDIFunc.trace(false);

(
MIDIdef.cc(\fader1, {
	arg val, num, chan;
	[val, num, chan].postln;
	x.set(\grn_dur, val.linlin(0,127,0.05,0.2));
}, 41).add;

MIDIdef.cc(\fader2, {
	arg val, num, chan;
	[val, num, chan].postln;
	x.set(\grn_rate, val.linlin(0,127,0,1));
}, 42).add;

MIDIdef.cc(\fader3, {
	arg val, num, chan;
	[val, num].postln;
	x.set(\dens, val.linlin(0,127,50,300));
}, 43).add;

MIDIdef.cc(\fader4, {
	arg val, num, chan;
	[val, num].postln;
	x.set(\postn_rand, val.linlin(0,127,0.01,1));
}, 44).add;
)

// Read wav file to buffer 'b'
(
b = Buffer.readChannel(
	s,
	"/home/sammi/Downloads/Alicia/christina.wav",
	channels:[0]
);
)

// play the buffer
b.play;

// clear/stop the buffer
b.free;

b.numChannels;

FreqScope.new;


// Synths for signal generation
(
// Basic Sine tone to test audio routing and FX
SynthDef(\test, {
	arg out=0, freq=440, mul=0.1;
	var sig;
	sig = SinOsc.ar(freq, 0, mul)!2;
	Out.ar(out, sig);
}).add;

// Main granular synth for buffer playback
SynthDef(\gs, {
	arg out=0, buf=b, grn_dur=0.2, grn_rate=1, postn_rand=0.01, dens=100,
	mul=0.3;
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(dens),
		grn_dur,
		buf,
		grn_rate,
		(
			Line.ar(0, BufSamples.ir(buf)-1, BufDur.ir(buf), doneAction:2)
			+ LFNoise1.ar(100).bipolar(postn_rand * SampleRate.ir)
		) / BufSamples.ir(buf), // position
		2, // linear
		0,
		-1, // use built-in Hann envelope
		512
	);
	sig = sig * mul;
	Out.ar(out, sig);
}).add;
)

// FX Section
(
SynthDef(\del, {
	arg out=0, in, deltime=0.3, mix=(-0.5), amp=1, rate=0.3, hzMin=0.1,
	hzMax=0.4;
	var sig, del;
	sig = In.ar(in, 2) * amp;
	del = DelayL.ar(
		sig[0,1],
		0.5,
		SinOsc.kr(rate).exprange(hzMin, hzMax),
	);
	sig = XFade2.ar(sig, del, mix);
	Out.ar(out, sig);
}).add;

SynthDef(\reverb, {
	arg out=0, in, mix=0.33, room=0.5, damp=0.5, amp=1, mul=0.3;
	var sig, verb;
	sig = In.ar(in, 2) * amp;
	verb = FreeVerb2.ar(sig[0], sig[1], mix, room, damp, mul);
	Out.ar(out, verb);
}).add;
)

// Dedicated private audio busses (i.e. cables between each synth)
(
~delBus = Bus.audio(s, 2);
~verbBus = Bus.audio(s, 2);
)

// Organize Synths into groups for easier management
(
~playbackGrp = Group.new;
~fxGrp = Group.after(~playbackGrp);
)

// Create & play new synths in their dedicated groups, using dedicated busses
(
~verb.free;
~verb = Synth.new(
	\reverb,
	[
		\out, 0,
		\in, ~verbBus,
		\mix, 0.5,
		\room, 0.8,
		\damp, 0.5,
		\mul, 0.5
	],
	~fxGrp
);

~del.free;
~del = Synth.new(
	\del,
	[
		\out, ~verbBus,
		\in, ~delBus,
		\deltime, 0.5,
		\mix, (1), // -1 = sig, 1 = del
		\amp, 1
	],
	~fxGrp
);
)

(
~gsFX = Synth.new(\gs, [\out, ~delBus], ~playbackGrp);
~gsDirect = Synth.new(\gs, [\out, 0], ~playbackGrp);
~testFX = Synth.new(\test, [\out, ~delBus], ~fxGrp);
~testDirect = Synth.new(\test, [\out, 0], ~playbackGrp);
)

// Stop test tones
(
~testDirect.free;
~testFX.free;
~gsFX.free;
~gsDirect.free;
)

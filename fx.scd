// =====================================================================
// SuperCollider Workspace
// =====================================================================

(
s.boot;
MIDIIn.connectAll;
)

s.prepareForRecord("/home/sammi/Recordings/hammer1.wav", numChannels:2);

s.record;

s.pauseRecording;

s.stopRecording;

(
s.meter;
s.plotTree;
s.scope;
)


b = Buffer.readChannel(s, "/home/sammi/Downloads/Alicia/radio_smash.wav");
b.numChannels;
b.free;

(
// FX Section
SynthDef(\srr, {
	|out=0, in, mix=1, rate=20000, mul=1|
	var sig, fx, final;
	sig = In.ar(in, 2);
	fx = Latch.ar(sig, Impulse.ar(rate));
	final = XFade2.ar(sig, fx, mix);
	final = final * mul;
	Out.ar(out, final);
}).add;

SynthDef(\bp, {
	|out=0, in, freq=440, rq=1, mix=1, mul=1|
	var sig, fx, final;
	sig = In.ar(in, 2);
	fx = BPF.ar(sig, freq, rq) * mul;
	final = XFade2.ar(sig, fx, mix);
	final = final * mul;
	Out.ar(out, final);
}).add;

SynthDef(\dist, {
	|out=0, in, mix=1, amp=100, mul=1|
	var sig, fx, final;
	sig = In.ar(in, 2);
	fx = (sig * amp).tanh;
	final = XFade2.ar(sig, fx, mix);
	final = final * mul;
	Out.ar(out, final);
}).add;

SynthDef(\folder, {
	|out=0, in, mix=1, amp=100, mul=1|
	var sig, fx, final;
	sig = In.ar(in, 2) * amp;
	fx = sig.fold2;
	final = XFade2.ar(sig, fx, mix);
	final = final * mul;
	Out.ar(out, final);
}).add;

SynthDef(\masterVol, {
	|out=0, in, mul=1|
	var sig;
	sig = In.ar(in, 2) * Lag.kr(mul, 0.1);
	Out.ar(out, sig);
}).add;

SynthDef(\bufplay, {
	|out=0, buf, channels=2|
	var sig;
	sig = PlayBuf.ar(
		2,
		buf,
		BufRateScale.ir(buf),
		loop:1
	);
	Out.ar(out, sig);
}).add;

SynthDef(\test, {
	|out=0, freq=440, mul=1|
	var sig;
	sig = SinOsc.ar(freq,0,mul)!2;
	Out.ar(out, sig);
}).add;
)

(
~g = Group.new;
~f = Group.after(~g);
)

(
~srrBus = Bus.audio(s, 2);
~bpBus = Bus.audio(s, 2);
~distBus = Bus.audio(s, 2);
~foldBus = Bus.audio(s, 2);
~msBus = Bus.audio(s, 2)
)

(
~vol = Synth(\masterVol, [\out, 0, \in, ~msBus], ~f);
~srr = Synth(\srr, [\out, ~msBus, \in, ~srrBus], ~f);
~fold = Synth(\fold, [\out, ~srrBus, \in, ~foldBus], ~f);
~dist = Synth(\dist, [\out, ~foldBus, \in, ~distBus], ~f);
~bp = Synth(\bp, [\out, ~distBus, \in, ~bpBus], ~f);
)

~play = Synth(\bufplay, [\buf, b], ~g);
~test = Synth(\test, ~g);
~play.free;
~test.free;
~f.free;
~g.free;
Cable modem and CMTS IP Simulator
---------------------------------

Run the demo
============
<pre>
rebar compile
cd ebin
erl 
application:start(cablesim).
</pre>
will simulate 5000 cable modems with mta and cpe booting on a cmts.

Background
==========
I work with cable modem provisioning systems. I often have a need to test the 
provisioning systems. It takes a lot of time to find, attach, get online etc.
a test cable modem - let alone the time it takes to "clean up" in the 
different provisioning systems after any previous use of that cable modem.

Likewise, stress- and performance testing the provisioning systems is challenging.
I have therefore looked around for software simulation solutions to this problem.
Without any success. There are companies selling solutions that can mimic any
single device. However, in the cable modem world - and seen from the provisoning
systems' perspective, the customer end devices are really "masqueraded" behind
the Cable Modem Termination Systems (CMTS). That is, seen from the provisioning
systems the CMTS does all the DHCP, TFTP and ToD relaying. 

I have therefore set out to write a CMTS + Cable modem (and, as soon as time allows
it, MTA/SIP and CPE) simulation software. I want it immediately scalable. Running
something on the order of 10 CMTSes each with 5000 cable modems, 5000 mtas and
5000 CPEs attached is my goal.

This is the reason I chose Erlang - with each component being a process (or a combination
of processes) with several small state machines / servers, it should be possible to
scale up indefinitely using Erlang's distributed mechanisms while still maintaining
a central point of control / configuration. But that remains to be seen, this is after
all my first Erlang program. It is a very draft first version. Currently completed is:

- A simple CMTS simulation that implements DHCP relay.
- A simple cable modem simulation that implelements DHCP client protocol.

Needless to say, a lot of features are missing. In somewhat prioritized order my list is:

- [2013-03-12 DONE] Add device "signatures" (ie. option 43 etc.) so we can mimic the DHCP client packets sent
  by the different manufacturers' devices.
- [2013-03-14 DONE - dhcp only] Make it possible to have different DHCP, TFTP, ToD etc. protocol modules
   to simulate different device behaviours, even faulty devices.
- [2013-03-14 DONE - dhcp only] Make it possible to build a multifunction cable modem device by combining
   - Cable modem DHCP + TFTP + ToD simulator
   - DHCP + TFTP simulator for an embedded MTA or SIP device
   - DHCP simulator for an embedded CPE device (router)
- Write TFTP and ToD state machine modules, so a IP complete cable modem with embedded mta/cpe can
  be emulated.
- Combine the DHCP, TFTP and ToD modules into a much more complete cable modem simulator.

Ideas boiling up:
- On-demand service: ReSTful web service interface to create a device on-demand and 
  put it "online".
- A subscriber behaviour simulation component, ie code that simulates different 
  customer behaviour: how often is the modem reset, poweroff, poweron, at what time 
  schedules etc.
- Feed back to graphite or similar to get performance graphs
- Configuration - some way of describing and executing different scenarios

/Jacob Lorensen
<jalor@yousee.dk>

Various links:
- http://www.tcpipguide.com/free/t_DHCPGeneralOperationandClientFiniteStateMachine.htm
- http://www.erlang.org/doc/reference_manual/records.html
- http://www.erlang.org/doc/design_principles/fsm.html
- http://www.erlang.org/doc/reference_manual/modules.html
- https://github.com/yrashk/gen_fsm2/blob/master/example/src/example_fsm.erl
- http://www.erlang.org/documentation/doc-4.8.2/doc/design_principles/fsm.html

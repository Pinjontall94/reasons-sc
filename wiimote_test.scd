// =====================================================================
// SuperCollider Workspace
// =====================================================================

HID.findAvailable; // check which devs are attached
HID.postAvailable; // list all available devs
~myhid = HID.open( 1406, 774 ); // open wiimote by vendor & product ID

HID.debug = true;
HIDFunc.trace( true );

"ls /dev/hidraw* -lah".unixCmd;
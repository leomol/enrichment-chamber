/**
 * @brief Arduino control program to report RFID tag detection from 4 RFID sensors in the Enrichment Chamber.
 * @author Leonardo Molina (leonardomt@gmail.com).
 * @file RFID.ino
 * @date 2023-10-03
 * @version: 0.1.0
*/

#include <SoftwareSerial.h>
#define PC Serial
#define S1 Serial1
#define S2 Serial2
#define S3 Serial3

SoftwareSerial S4(A8, A8);

const uint8_t nRF = 4;
Stream* RF[nRF];

// Baudrate of serial communication with the PC.
const uint32_t baudrate = 115200;
uint8_t tag[20] = {0};
uint8_t tagSize = 0;

void setup() {
	// Start both hardware and software serial streams.
	S1.begin(9600);
	S2.begin(9600);
	S3.begin(9600);
	S4.begin(9600);
	
	RF[0] = &S1;
	RF[1] = &S2;
	RF[2] = &S3;
	RF[3] = &S4;
	
	// Wait for connection from PC.
	PC.begin(baudrate);
	while (!PC)
		delay(10);
	
	// Report start with expected format.
	PC.println("0,0,0");
}

/** 
 * Check for incoming messages from any of the RFID sensors.
 */
void loop() {
	int8_t i = 0;
	for (int8_t i = 0; i < nRF; i++) {
		// Parse data from RFID reader.
		while (RF[i]->available() > 0) {
			// Data format: 2, a, b, ..., 10, 13, 3
			char input = RF[i]->peek();
			if (input == 2) { // STX.
				RF[i]->read();
				tagSize = 0;
			} else if (input == 3) { // ETX.
				tagSize -= 2; // Do not include 10 and 13
				RF[i]->read();
				reportTag(i);
			} else {
				tag[tagSize++] = RF[i]->read();
			}
		}
	}
}

/** 
 * Report timestamp, sensor id, and tag detected.
 *
 * # @param sensorId Id of RFID sensor.
*/
void reportTag(uint8_t sensorId) {
	char const hex[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
	PC.print(String() + millis() + "," + sensorId + ",");
	for (int i = 0; i < tagSize; i++) {
		PC.print(hex[(tag[i] & 0xF0) >> 4]);
		PC.print(hex[(tag[i] & 0x0F) >> 0]);
	}
	PC.println();
}
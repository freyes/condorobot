/* Felipe Reyes <freyes@tty.cl>
 * This program it's the one that runs my attempt to build a robot,
 * so it's a mix of things found in the net.
 *
 * Code took from the following examples, tutorial and other sutffs
 * PlayMelody: http://www.arduino.cc/en/Tutorial/PlayMelody
 *
 */
// TONES  ==========================================
// Start by defining the relationship between
//       note, period, &  frequency.
#define  c     3830    // 261 Hz
#define  d     3400    // 294 Hz
#define  e     3038    // 329 Hz
#define  f     2864    // 349 Hz
#define  g     2550    // 392 Hz
#define  a     2272    // 440 Hz
#define  b     2028    // 493 Hz
#define  C     1912    // 523 Hz
// Define a special note, 'R', to represent a rest
#define  R     0
// Set up speaker on a PWM pin (digital 9, 10 or 11)
int speakerOut = 7;

// MELODY and TIMING  =======================================
//  melody[] is an array of notes, accompanied by beats[],
//  which sets each note's relative length (higher #, longer note)
int melody[] = {  C,  b,  g,  C,  b,   e,  R,  C,  c,  g, a, C };
int beats[]  = { 16, 16, 16,  8,  8,  16, 32, 16, 16, 16, 8, 8 };
int MAX_COUNT = sizeof(melody) / 2; // Melody length, for looping.

// Set overall tempo
long tempo = 10000;
// Set length of pause between notes
int pause = 1000;
// Loop variable to increase Rest length
int rest_count = 100; //<-BLETCHEROUS HACK; See NOTES

// Initialize core variables
int tone = 0;
int beat = 0;
long duration  = 0;

//
int NOT_AVAILABLE = -1;
int AVAILABLE = 0;
int STRAIGHT = 1;
int TURN_LEFT = 2;

// Motor A == LEFT
int motorL1Pin = 5;    // H-bridge leg 1 (pin 2, 1A)
int motorL2Pin = 6;    // H-bridge leg 2 (pin 7, 2A)
int enableLPin = 3;    // H-bridge enable pin

// motor B == RIGHT
int motorR1Pin = 10;    // H-bridge leg 3 (pin 10, 3A)
int motorR2Pin = 9;    // H-bridge leg 4 (pin 15, 4A)
int enableRPin = 11;    // H-bridge enable pin

int ledPin = 13;      // LED
int pushButton = 8;

int potval = 220;       // variable to store the value coming from the sensor


int state = LOW;      // the current state of the output pin
int reading;           // the current reading from the input pin
int previous = LOW;    // the previous reading from the input pin

// the follow variables are long's because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long time = 0;         // the last time the output pin was toggled
long debounce = 200;   // the debounce time, increase if the output flickers


int motorBusy = AVAILABLE;
int timeBusy = 0;


int mayIuseMotors (int operation, int milliSecs);
void turnLeft (int ratioDegrees, int milliSecs);
void straight (int milliSecs);
void blink(int whatPin, int howManyTimes, int milliSecs);
void playTone();

void setup() {

  Serial.begin(115200);
  Serial.println("Serial output");

  // setup digital pins
  pinMode(enableLPin, OUTPUT);
  pinMode(enableRPin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  pinMode(pushButton, INPUT);
  pinMode(speakerOut, OUTPUT);

  // set to low so that motor start turned off:
  digitalWrite(enableLPin, LOW);
  digitalWrite(enableRPin, LOW);

  // blink the LED 3 times. This should happen only once.
  // if you see the LED blink three times, it means that the module
  // reset itself,. probably because the motor caused a brownout
  // or a short.
  blink(ledPin, 3, 100);
}

void loop() {
  // if the switch is high, motor will turn on one direction:
  reading = digitalRead(pushButton);

  // if we just pressed the button (i.e. the input went from LOW to HIGH),
  // and we've waited long enough since the last press to ignore any noise...
  if (reading == HIGH && previous == LOW && millis() - time > debounce) {
    // ... invert the output
    if (state == HIGH)
      state = LOW;
    else
      state = HIGH;

    // ... and remember when the last button press was
    time = millis();
    // Set up a counter to pull from melody[] and beats[]
    for (int i=0; i<MAX_COUNT; i++) {
      tone = melody[i];
      beat = beats[i];

      duration = beat * tempo; // Set up timing

      playTone();
      // A pause between notes...
      delayMicroseconds(pause);

    }

  }

  digitalWrite(enableLPin, state);
  digitalWrite(enableRPin, state);
  if (state == HIGH)
    blink(ledPin, 1, 500);

  previous = reading;

  //analogWrite(motorL1Pin, potval);
  //analogWrite(motorL2Pin, 255-potval);
  //analogWrite(motorR1Pin, potval);
  //analogWrite(motorR2Pin, 255-potval);
  if (state == HIGH)
    {
      turnLeft(0, 3000);
      straight(10000);
    }
}

int mayIuseMotors (int operation, int milliSecs)
{
  if ((motorBusy != AVAILABLE) && (motorBusy != operation))
    return NOT_AVAILABLE;

  motorBusy = operation;

  if (timeBusy == 0)
    timeBusy = millis();

  if ((millis() - timeBusy) > milliSecs)
    {
      timeBusy = 0;
      motorBusy = AVAILABLE;
      return NOT_AVAILABLE;
    }
  else
    return AVAILABLE;
}

void turnLeft (int ratioDegrees, int milliSecs) {

  if (mayIuseMotors(TURN_LEFT, milliSecs) != AVAILABLE)
    return;

  if (ratioDegrees == 0)
    {
      analogWrite(motorL1Pin, 0);
      analogWrite(motorL2Pin, 120);
      analogWrite(motorR1Pin, 120);
      analogWrite(motorR2Pin, 0);
    }
}

void straight (int milliSecs)
{
  if (mayIuseMotors(STRAIGHT, milliSecs) != AVAILABLE)
    return;

  analogWrite(motorL1Pin, 100);
  analogWrite(motorL2Pin, 0);
  analogWrite(motorR1Pin, 100);
  analogWrite(motorR2Pin, 0);
}

/*
  blinks an LED
*/
void blink(int whatPin, int howManyTimes, int milliSecs) {
  int i = 0;
  for ( i = 0; i < howManyTimes; i++) {
    digitalWrite(whatPin, HIGH);
    delay(milliSecs/2);
    digitalWrite(whatPin, LOW);
    delay(milliSecs/2);
  }
}

// PLAY TONE  ==============================================
// Pulse the speaker to play a tone for a particular duration
void playTone() {
  long elapsed_time = 0;
  if (tone > 0) { // if this isn't a Rest beat, while the tone has
    //  played less long than 'duration', pulse speaker HIGH and LOW
    while (elapsed_time < duration) {

      digitalWrite(speakerOut,HIGH);
      delayMicroseconds(tone / 2);

      // DOWN
      digitalWrite(speakerOut, LOW);
      delayMicroseconds(tone / 2);

      // Keep track of how long we pulsed
      elapsed_time += (tone);
    }
  }
  else { // Rest beat; loop times delay
    for (int j = 0; j < rest_count; j++) { // See NOTE on rest_count
      delayMicroseconds(duration);
    }
  }
}

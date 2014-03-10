/* LedStripRainbow: Example Arduino sketch that shows
 * how to make a moving rainbow pattern on an
 * Addressable RGB LED Strip from Pololu.
 *
 * To use this, you will need to plug an Addressable RGB LED
 * strip from Pololu into pin 12.  After uploading the sketch,
 * you should see a moving rainbow.
 */
 
#include <PololuLedStrip.h>

// Create an ledStrip object and specify the pin it will use.
PololuLedStrip<12> ledStrip;

// Create a buffer for holding the colors (3 bytes per color).
#define LED_COUNT 60
rgb_color colors[LED_COUNT];
rgb_color current_color;

void setup()
{
  Serial.begin(115200);
  current_color = (rgb_color){0,0,255};
  Serial.println("Ready to receive colors."); 
}

void loop()
{
  // Update the colors.
  uint16_t time = millis() ;
  for(uint16_t i = 0; i < LED_COUNT; i++)
  {    
    byte slow = (time >> 5) - (i << 3);    
    byte pulse = (byte)(64.0*(sin(((float) slow)/(3.14/2.0))+1.5));
    colors[i] = (rgb_color){
      (int)pulse*(int)current_color.red/(int)255,
      (int)pulse*(int)current_color.green/(int)255,
      (int)pulse*(int)current_color.blue/(int)255
    };
  }
  ledStrip.write(colors, LED_COUNT);  
  
  if (Serial.available()>=4)
  {
    byte header = Serial.read();
    if(header!=32)
    {
      byte next = 0;
      for (int reparse = 0; reparse < 3; reparse++) {
        next = Serial.peek();
        if(next==32)
          {break;}
        else
          {Serial.read();}
      }
      if(next==32)
         {Serial.println("Error- resynchronized");}
      else
         {Serial.println("Error- unable to resynchronize");}
    }
    else
    {
      current_color.red=Serial.read();
      current_color.green=Serial.read();
      current_color.blue=Serial.read();
      Serial.print("Recieved color:");
      Serial.print(current_color.red,HEX);
      Serial.print(current_color.green,HEX);
      Serial.println(current_color.blue,HEX);
    }
  }  
}

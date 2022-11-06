
include "draw01.prg.h"

#define STROBE_FLG_PIN 11   
#define READY_DA2_PIN  10   
#define UDB0_PIN        9   
#define UDB1_PIN        8   
#define UDB2_PIN        7   
#define UDB3_PIN        6   
#define UDB4_PIN        5   
#define UDB5_PIN        4   
#define UDB6_PIN        3   
#define UDB7_PIN        2   

uint8_t UDBbitpin[] = { UDB0_PIN, UDB1_PIN, UDB2_PIN, UDB3_PIN, UDB4_PIN, UDB5_PIN, UDB6_PIN, UDB7_PIN };

void setup() 
{
  Serial.begin(115200);
  
  pinMode(STROBE_FLG_PIN, OUTPUT);
  digitalWrite(STROBE_FLG_PIN, 1);  //default high
  
  pinMode(READY_DA2_PIN, INPUT);
  
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) pinMode(UDBbitpin[bitnum], OUTPUT);
  SetParallel(0);

  Serial.println("\n\nTrav's C64 User Port Project");
} 
  
void loop()
{
  static uint8_t Count = 0;
  
  while (!Serial.available()); //wait for char
  while (Serial.available()) Serial.read(); //read all
   
  for(uint8_t bytenum = 0; bytenum < 64; bytenum++) WriteByte(Count++);
  // 11/6/22:  64 bytes takes ~2.5mS, 204800bps!
  
  Serial.println("Packet sent, ready for another");
  
}  
  
void WriteByte(uint8_t val)
{
  while (!digitalRead(READY_DA2_PIN)); //wait for ready
  SetParallel(val);
  digitalWrite(STROBE_FLG_PIN, 0);
  //duty cycle doesn't matter, but must wait for not ready
  while (digitalRead(READY_DA2_PIN)); 
  digitalWrite(STROBE_FLG_PIN, 1);

} 
  
void SetParallel(uint8_t val)
{
  for(uint8_t bitnum = 0; bitnum < 8; bitnum++) digitalWrite(UDBbitpin[bitnum], val & (1<<bitnum));
}


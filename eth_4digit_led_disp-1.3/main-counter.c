/*********************************************
* vim:sw=8:ts=8:si:et
* To use the above modeline in vim you must have "set modeline" in your .vimrc
*
* 4 Digit LED display with large segments, counter code
* UDP and HTTP interface 
*
* Author: Guido Socher, Copyright: BSD 2 license
*
* Copyright (c) 2014, Guido Socher
* All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* 
* 1. Redistributions of source code must retain the above copyright notice,
* this list of conditions and the following disclaimer.
* 
* 2. Redistributions in binary form must reproduce the above copyright
* notice, this list of conditions and the following disclaimer in the
* documentation and/or other materials provided with the distribution.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
* HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* 
* See http://www.tuxgraphics.org/electronics/
* 
* Chip type: Atmega328 with ENC28J60
*********************************************/
#include <avr/io.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>
#include "ip_arp_udp_tcp.h"
#include "websrv_help_functions.h"
#include "enc28j60.h"
#include "timeout.h"
#include "net.h"

// This software is a web server only. 
//
// please modify the following two lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static uint8_t mymac[6] = {0x54,0x55,0x58,0x10,0x09,0x4};
//static uint8_t myip[4] = {10,0,0,29};
static uint8_t myip[4] = {192,168,100,220};
// listen port for tcp/www:
static uint16_t mywwwport=80;
// listen port for udp:
static uint16_t myudpport=1200;
// ---------------end modify
// global string buffer
#define STR_BUFFER_SIZE 20
static char gStrbuf[STR_BUFFER_SIZE+1]="";
static char gPrevValue[STR_BUFFER_SIZE+1]="0";
#define BUFFER_SIZE 650
static uint8_t buf[BUFFER_SIZE+1];
// name of this switch (title on the main webpage)
static char label[22]="4 digit counter"; // must not be longer than 21 char
static uint8_t gModifyip=0;  // 1 means change
//
//
//Connections of the seven segment elements:
//   0|  01110111 | 77
//   1|  00010100 | 14
//   2|  10110011 | b3
//   3|  10110110 | b6
//   4|  11010100 | d4
//   5|  11100110 | e6
//   6|  11100111 | e7
//   7|  00110100 | 34
//   8|  11110111 | f7
//   9|  11110110 | f6
// digit to seven segment LED mapping:
static unsigned char d2led[]={0x77,0x14,0xb3,0xb6,0xd4,0xe6,0xe7,0x34,0xf7,0xf6};
// bit pattern to switch the decimal dot on (or this with the digit value):
#define DOT_ON 8
// bit pattern to display a dash:
#define DASH_ON 0x80
// set output to VCC, red LED off
#define LEDOFF PORTB|=(1<<PORTB1)
// set output to GND, red LED on
#define LEDON PORTB&=~(1<<PORTB1)
// to test the state of the LED
#define LEDISOFF PORTB&(1<<PORTB1)
// 
// SER pin 14:
#define S74595_0 PORTD&=~(1<<PORTD3)
#define S74595_1 PORTD|=(1<<PORTD3)
// RCLK pin 12:
#define S74595_RCLKDOWN PORTD&=~(1<<PORTD2)
#define S74595_RCLKUP PORTD|=(1<<PORTD2)
// SRCLK pin 11:
#define S74595_CLOCKDOWN PORTD&=~(1<<PORTD1)
#define S74595_CLOCKUP PORTD|=(1<<PORTD1)
// Inline assembly, nop = do nothing for a clock cycle.
//#define nop()  asm volatile("nop\n\t" "nop\n\t"::)
#define nop()  asm volatile("nop\n\t"::)

uint16_t http200ok(void)
{
        return(fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nPragma: no-cache\r\n\r\n")));
}

void set74595(uint8_t val[4])
{
      int8_t j=3;
      uint8_t i;
      while(j>=0){
              i=8;
              while(i){
                      i--;
                      S74595_CLOCKDOWN;
                      if (val[j] & (1<<i)){
                              S74595_1;
                      }else{
                              S74595_0;
                      }
                      S74595_CLOCKUP;
                      nop();
              }
              j--;
      }
      S74595_CLOCKDOWN;
      S74595_RCLKUP;
      nop();
      S74595_RCLKDOWN;
}
void init74595(void)
{
        uint8_t cleardisp[4]={0,0,0,0};
        DDRD|= (1<<DDD2); // enable as output line, RCLK (shift to display)
        S74595_RCLKDOWN;
        DDRD|= (1<<DDD3); // enable as output line, SER (serial-in)
        S74595_0;
        DDRD|= (1<<DDD1); // enable as output line, SRLCL (serial-clk)
        S74595_CLOCKDOWN;
        set74595(cleardisp);
}

uint16_t print_webpage_syntax_error(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>Syntax Error</h2>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("<pre>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("Possible values are:\n\
1234\n\
12:34\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("\n<a href=/>continue...</a>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("\n</pre><hr>\n"));
        return(pl);
}

uint16_t print_webpage_status(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<a href=/>[home]</a> "));
        pl=fill_tcp_data_p(buf,pl,PSTR("<a href=/get>[refresh]</a>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>"));
        pl=fill_tcp_data(buf,pl,label);
        pl=fill_tcp_data_p(buf,pl,PSTR(", status</h2>\n<pre>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("counter: "));
        pl=fill_tcp_data(buf,pl,gPrevValue);
        pl=fill_tcp_data_p(buf,pl,PSTR("\n</pre><hr>\n"));
        return(pl);
}

// main webpage
uint16_t print_webpage_main(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<a href=./>[refresh]</a> "));
        pl=fill_tcp_data_p(buf,pl,PSTR("<a href=/get>[status]</a>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>"));
        pl=fill_tcp_data(buf,pl,label);
        pl=fill_tcp_data_p(buf,pl,PSTR("</h2>\n<pre>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("\
<form action=set method=get>\n\
Value: <input type=text name=n size=17> <input type=submit value=\"set\">\n\
</form>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("\n</pre><hr>\n"));
        return(pl);
}

// parses a sting of the form
// 1234
// or
// 12:34
// or
// 1.234
// or
// 1.2.:3.4.
// or
// 1. .:3.4.
// or
// 1.-.:3.4.
// or
// 3.4
// and updates the display accordingly
int8_t set_display_from_string(char *str)
{
        uint8_t have_colon=0;
        int8_t i=3;
        int8_t digit=0;
        uint8_t dval[4]={0,0,0,0};
        size_t len;
        len=strnlen(str,10);
        if (len>9){
                return(1); // error
        }
        if (len<1){
                // clear display
                set74595(dval);
                PORTD |= (1<<PORTD0);// output on, LED-dots off
                return(0);
        }
        // parse from the end:
        while(len && i>=0){
                len--;
                if (isdigit(str[len])){
                        digit=str[len] - '0';
                        dval[i]|=d2led[digit];
                        i--;
                }else if (str[len]=='-'){
                        dval[i]|=DASH_ON;
                        i--;
                }else if (str[len]==':'){
                        have_colon=1;
                }else if (str[len]==' '){
                        dval[i]=0;
                        i--;
                }else if (str[len]=='.'){
                        dval[i]|=DOT_ON; // note: in the string we find firts the dot and then the digit
                }else{
                        return(1); // error
                }
        }
        set74595(dval);
        if (have_colon){
                PORTD &= ~(1<<PORTD0);// output off, LED-dots on
        }else{
                PORTD |= (1<<PORTD0);// output on, LED-dots off
        }
        return(0);// all ok
}

// remove any non digit character
uint8_t parse_str_rm_colon(char *s){
        uint8_t had_colon=0;
        char *dst;
        dst=s;
        while(*s){
                if (*s==':'){
                        had_colon=1;
                }
                if(isdigit(*s)){
                        *dst=*s;
                        dst++;
                }
                s++;
        }
        *dst='\0';
        return(had_colon);
}

void insert_conlon_and_zero_pad(char *str,uint8_t digits_to_pad_to,uint8_t add_colon){
	char *s;
	char workbuf[14];
	uint8_t slen;
	uint8_t i;
	uint8_t dc=0;
	slen=strlen(str);
        // worst case sanity check
        if ((int8_t)sizeof(workbuf)-4 < digits_to_pad_to){
                // not enough space
                return;
        }
	// count digits and copy to work buffer
	s=str;
	while(*s){
		if (isdigit(*s)) dc++;
		s++;
	}
        s=workbuf; // empty buffer
	if (dc<digits_to_pad_to){
                i=digits_to_pad_to-dc; // amount of zeros to add
                while(i){
                        *s='0';
                        i--;
                        s++;
                }
        }
        strcpy(s,str); // append to workbuf after the padding
        if (add_colon){
                slen=strlen(workbuf);
                //shift:
                workbuf[slen+1]='\0';
                i=0; // how many char we shifted in the loop:
                while(slen && i<2){
                        workbuf[slen]=workbuf[slen-1];
                        slen--;
                        i++; 
                }
                workbuf[slen]=':';
        }
	strcpy(str,workbuf); 
}
		
// takes a string of the form command/Number and analyse it (e.g "set?n=1234&a=1 HTTP/1.1")
// The first char of the url ('/') is already removed.
int8_t analyse_get_url(char *str)
{
        int16_t i=0;
        uint8_t had_colon=0;
        uint8_t had_leading_zero=0;
        if (str[0]==' '){
                return(1); // end of url, main page
        }
        if (strncmp("set",str,3)==0){
                if (find_key_val(str,gStrbuf,STR_BUFFER_SIZE,"n")){
                        urldecode(gStrbuf);
                        gStrbuf[sizeof(gStrbuf)-1]='\0';
                        // we change gStrbuf and remove any non digits
                        had_colon=parse_str_rm_colon(gStrbuf);
                        // convert number string to integer:
                        i=atol(gStrbuf);
                        if (i>9999 || i<0) i=0; // wrap
                        // check for leading zero
                        if (strlen(gStrbuf)>1 && gStrbuf[0]=='0') had_leading_zero=1;
                        ltoa(i,gStrbuf,10); // convert integer to string
                        if (had_leading_zero){
                                if (i>=100){ // 0100
                                        had_leading_zero=4;
                                }else if(i>=10){ // 010
                                        had_leading_zero=3;
                                }else{
                                        had_leading_zero=2;
                                }
                        }
                        insert_conlon_and_zero_pad(gStrbuf,had_leading_zero,had_colon);
                        if (set_display_from_string(gStrbuf)==0){
                                strcpy(gPrevValue,gStrbuf);
                                return(1); // main page
                        }else{
                                return(2); // error page
                        }
                }
        }
        if (strncmp("get",str,3)==0){
                return(3); // status page, get display value
        }
        return(0);
}

//-------------------- start of modify ip functions
uint16_t print_modifyip(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>Settings</h2><pre>\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("<form action=/i method=get>"));
        pl=fill_tcp_data_p(buf,pl,PSTR("new IP: <input type=text name=nip value="));
        mk_net_str(gStrbuf,myip,4,'.',10);
        pl=fill_tcp_data(buf,pl,gStrbuf);
        pl=fill_tcp_data_p(buf,pl,PSTR(">\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("label : <input type=text name=l value=\""));
        pl=fill_tcp_data(buf,pl,label);
        pl=fill_tcp_data_p(buf,pl,PSTR("\">\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("udp port: <input type=text size=4 name=up value="));
        itoa(myudpport,gStrbuf,10); // convert integer to string
        pl=fill_tcp_data(buf,pl,gStrbuf);
        pl=fill_tcp_data_p(buf,pl,PSTR("> "));
        pl=fill_tcp_data_p(buf,pl,PSTR("http port: <input type=text size=4 name=hp value="));
        itoa(mywwwport,gStrbuf,10); // convert integer to string
        pl=fill_tcp_data(buf,pl,gStrbuf);
        pl=fill_tcp_data_p(buf,pl,PSTR(">\n"));
        pl=fill_tcp_data_p(buf,pl,PSTR("<input type=submit value=\"change\"></form>\nMac-addr. of this board: "));
        mk_net_str(gStrbuf,mymac,6,':',16);
        pl=fill_tcp_data(buf,pl,gStrbuf);
        pl=fill_tcp_data_p(buf,pl,PSTR("\n<hr>"));
        return(pl);
}

uint16_t print_modifyip_confirm(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>OK</h2> Release buttons and power cycle.\n"));
        return(pl);
}

uint16_t print_modifyip_fail(void)
{
        uint16_t pl;
        pl=http200ok();
        pl=fill_tcp_data_p(buf,pl,PSTR("<h2>ERROR</h2> Data might be inconsistent. Try again.\n"));
        return(pl);
}

// return -1 in case of error:
int8_t store_new_ip_pw(char *str)
{
        if (find_key_val(str,label,sizeof(label),"l")){
                urldecode(label);
                label[sizeof(label)-1]='\0';
                eeprom_write_block((uint8_t *)label,(void *)20,sizeof(label));
        }
        if (find_key_val(str,gStrbuf,STR_BUFFER_SIZE,"up")){
                urldecode(gStrbuf);
                gStrbuf[4]='\0'; // limit to 4 digits
                mywwwport=atoi(gStrbuf);
                eeprom_write_word((void *)7,myudpport);
        }
        if (find_key_val(str,gStrbuf,STR_BUFFER_SIZE,"hp")){
                urldecode(gStrbuf);
                gStrbuf[4]='\0'; // limit to 4 digits
                mywwwport=atoi(gStrbuf);
                eeprom_write_word((void *)5,mywwwport);
        }
        if (find_key_val(str,gStrbuf,STR_BUFFER_SIZE,"nip")){
                urldecode(gStrbuf);
                if (parse_ip(myip,gStrbuf)==0){
                        // store IP in eeprom:
                        eeprom_write_byte((uint8_t *)0x0,19); // magic number
                        eeprom_write_block((uint8_t *)myip,(void *)1,sizeof(myip));
                        return(0);
                }
        }
        return(-1);
}

void init_modify_ip(void){
        // press upper button PD6 at power-on =change IP mode
        DDRD&= ~(1<<PIND6);
        PORTD|=1<<PIND6; // internal pullup resistor on
        _delay_loop_1(0); // 60us
        if (bit_is_clear(PIND,PIND6)){
                gModifyip=1;
                // make eeprom data invalid
                eeprom_write_byte((uint8_t *)0x0,1); // delete magic number
        }
        if (gModifyip==0 && eeprom_read_byte((uint8_t *)0x0) == 19){
                // ok magic number matches accept values
                eeprom_read_block((uint8_t *)myip,(void *)1,sizeof(myip));
                mywwwport=(uint16_t)eeprom_read_word((void *)5);
                myudpport=(uint16_t)eeprom_read_word((void *)7);
                eeprom_read_block((char *)label,(void *)20,sizeof(label));
                label[sizeof(label)-1]='\0';
        }
}
//-------------------- end of modify ip functions

int main(void){
        uint16_t dat_p,plen;
        int8_t cmd;
        uint8_t cmd_pos=0;
        uint16_t payloadlen=0;
        int16_t idisp=0;
        uint16_t debounce=0;
        uint8_t one_zero[4]={0,0,0,d2led[0]};
        uint8_t had_colon=0;
        uint8_t had_leading_zero=0;
        uint8_t fastscroll=0;
        
        init74595(); // it is best to do 74hc595 init right after power on
        set74595(one_zero);
        strcpy(gPrevValue,"0");

        // set the clock speed to "no pre-scaler" (8MHz with internal osc or 
        // full external speed)
        // set the clock prescaler. First write CLKPCE to enable setting 
        // of clock the next four instructions.
        // Note that the CKDIV8 Fuse determines the initial
        // value of the CKKPS bits.
        CLKPR=(1<<CLKPCE); // change enable
        CLKPR=0; // "no pre-scaler"
        _delay_loop_1(0); // 60us

        /*initialize enc28j60*/
        enc28j60Init(mymac);
        enc28j60clkout(2); // change clkout from 6.25MHz to 12.5MHz
        _delay_loop_1(0); // 60us
        
        /* Magjack leds configuration, see enc28j60 datasheet, page 11 */
        // LEDB=yellow LEDA=green
        //
        // 0x476 is PHLCON LEDA=links status, LEDB=receive/transmit
        // enc28j60PhyWrite(PHLCON,0b0000 0100 0111 01 10);
        enc28j60PhyWrite(PHLCON,0x476);
        
        DDRB|= (1<<DDB1); // as output, debug LED on the eth board
        LEDOFF;
        // the led-dots:
        DDRD|= (1<<DDD0);
        PORTD |= (1<<PORTD0);// output on, LED-dots off

        init_modify_ip(); // reads also mywwwport and myudpport
        
        if (gModifyip==0){
                // up button for counter:
                DDRD&= ~(1<<PIND6);
                PORTD|=1<<PIND6; // internal pullup resistor on
                // down button for counter:
                DDRB&= ~(1<<PINB0);
                PORTB|=1<<PINB0; // internal pullup resistor on
        }

        //init the ethernet/ip layer:
        init_udp_or_www_server(mymac,myip);
        www_server_port(mywwwport);

        while(1){

                // handle ping and wait for a tcp packet
                plen=enc28j60PacketReceive(BUFFER_SIZE, buf);
                dat_p=packetloop_arp_icmp_tcp(buf,plen);

                if(dat_p==0){
                        // check if udp otherwise continue
                        goto UDP;
                }
                // check for too short requests or non GET requests (head, post and other methods):
                if (dat_p + 10 > plen || strncmp("GET ",(char *)&(buf[dat_p]),4)!=0){
                        // for possible status codes see:
                        // http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
                        plen=fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 501 Not Implemented\r\nContent-Type: text/html\r\n\r\n"));

                        plen=fill_tcp_data_p(buf,plen,PSTR("<h1>501 Not Implemented</h1>"));
                        goto SENDTCP;
                }
                // The buf contains the whole HTTP header and body.
                // We can cut down the size because we know that our
                // data is in the URL part:
                buf[BUFFER_SIZE]='\0';
                if ((dat_p+5+100) < BUFFER_SIZE){
                        buf[dat_p+5+100]='\0';
                }
                // modify IP settings
                if (gModifyip){
                        if (buf[dat_p+5] == 'i'){
                                // returns 10 or -1:
                                if (store_new_ip_pw((char *)&(buf[dat_p+5]))==0){
                                        plen=print_modifyip_confirm();
                                }else{
                                        plen=print_modifyip_fail();
                                }
                        }else{
                                plen=print_modifyip();
                        }
                        goto SENDTCP;
                }
                // remove the first slash:
                cmd=analyse_get_url((char *)&(buf[dat_p+5]));
                // for possible status codes see:
                // http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
                if (cmd==0){
                        plen=fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 401 Unauthorized\r\nContent-Type: text/html\r\n\r\n<h1>401 Unauthorized</h1>"));
                        goto SENDTCP;
                }
                if (cmd==2){
                        plen=print_webpage_syntax_error();
                        goto SENDTCP;
                }
                if (cmd==3){
                        plen=print_webpage_status();
                        goto SENDTCP;
                }
                plen=print_webpage_main();
                //
SENDTCP:
                www_server_reply(buf,plen); // send data
                continue;
                // tcp port www end
                // -----------------------------
                // udp start, we listen on udp port 1200=0x4B0
UDP:
                if (myudpport==0){ // 0=disable udp
                        continue;
                }
                // check if ip packets are for us:
                if(eth_type_is_ip_and_my_ip(buf,plen)==0){
                        // no data for me, do other tasks:
                        //
                        // up-down counter:
                        if (debounce) debounce--;
                        if (gModifyip==0 && debounce==0){
                                if (bit_is_clear(PIND,PIND6)){
                                        if (fastscroll) fastscroll--;
                                        // count up
                                        //
                                        // we change gStrbuf and remove any non digits
                                        had_colon=parse_str_rm_colon(gPrevValue);
                                        // check for leading zero
                                        had_leading_zero=0;
                                        if (strlen(gPrevValue) > 1 && gPrevValue[0]=='0') had_leading_zero=1;
                                        idisp=atol(gPrevValue);
                                        idisp++;
                                        if (idisp>9999 || idisp<0) idisp=0; // wrap
                                        ltoa(idisp,gStrbuf,10); // convert integer to string
                                        if (had_leading_zero){
                                                if (idisp==100){ // 0100
                                                        had_leading_zero=4;
                                                }else if(idisp==10){ // 010
                                                        had_leading_zero=3;
                                                }else if(idisp==1 || idisp==0){ // 01, 00, 00 is the case of wrapping from 9999
                                                        had_leading_zero=2;
                                                }else{
                                                        had_leading_zero=strlen(gPrevValue);
                                                }
                                        }
                                        if (had_leading_zero> 4) had_leading_zero=4; // sanity check
                                        insert_conlon_and_zero_pad(gStrbuf,had_leading_zero,had_colon);
                                        if (set_display_from_string(gStrbuf)==0){
                                                strcpy(gPrevValue,gStrbuf);
                                        }
                                        if (fastscroll==0){
                                                debounce=0x0fff;
                                        }else{
                                                debounce=0x1fff;
                                        }
                                }else if (bit_is_clear(PINB,PINB0)){
                                        if (fastscroll) fastscroll--;
                                        // count down
                                        //
                                        // we change gStrbuf and remove any non digits
                                        had_colon=parse_str_rm_colon(gPrevValue);
                                        idisp=atol(gPrevValue);
                                        if (idisp>9999 || idisp<1) idisp=10000; // wrap
                                        // when counting down we will always add a zero: 100 - 1 = 099
                                        // We have to check if the original number was
                                        // something like 0100. This has to become
                                        // 099 not 0099
                                        if (idisp==100){ // -> 099
                                                had_leading_zero=3;
                                        }else if(idisp==10){ // 09
                                                had_leading_zero=2;
                                        }else{
                                                had_leading_zero=strlen(gPrevValue);
                                        }
                                        if (had_leading_zero> 4) had_leading_zero=4; // sanity check
                                        idisp--;
                                        ltoa(idisp,gStrbuf,10); // convert integer to string
                                        insert_conlon_and_zero_pad(gStrbuf,had_leading_zero,had_colon);
                                        if (set_display_from_string(gStrbuf)==0){
                                                strcpy(gPrevValue,gStrbuf);
                                        }
                                        if (fastscroll==0){
                                                debounce=0x0fff;
                                        }else{
                                                debounce=0x1fff;
                                        }
                                }else{
                                        fastscroll=12;
                                }
                        }
                        continue;
                        // end no data for me, end idle task
                }
                // udp
                if (buf[IP_PROTO_P]==IP_PROTO_UDP_V&&buf[UDP_DST_PORT_H_P]==(myudpport>>8)&&buf[UDP_DST_PORT_L_P]==(myudpport&0xff)){
                        payloadlen=buf[UDP_LEN_L_P]-UDP_HEADER_LEN;
                        cmd_pos=0;
                        if (payloadlen<2 || payloadlen> 20){
                                strcpy(gStrbuf,"e=inv_cmd");
                                goto ANSWER;
                        }
                        if (buf[UDP_DATA_P+cmd_pos]=='n' && buf[UDP_DATA_P+cmd_pos+1]=='='){
                                buf[UDP_DATA_P+cmd_pos+payloadlen]='\0';
                                // we use gStrbuf as well as an answer buffer where we add "n="
                                strncpy(gStrbuf,(char *)&(buf[UDP_DATA_P+cmd_pos+2]),STR_BUFFER_SIZE-3);
                                gStrbuf[STR_BUFFER_SIZE-3]='\0';
                                if (set_display_from_string(gStrbuf)==0){
                                        strcpy(gPrevValue,gStrbuf);
                                        gStrbuf[0]='n';
                                        gStrbuf[1]='=';
                                        strcpy(gStrbuf+2,gPrevValue);
                                        goto ANSWER;
                                }else{
                                        strcpy(gStrbuf,"e=inv_cmd");
                                        goto ANSWER;
                                }
                        }
                        if (buf[UDP_DATA_P+cmd_pos]=='g'){
                                buf[UDP_DATA_P+cmd_pos+payloadlen]='\0';
                                // we use gStrbuf as well as an answer buffer where we add "n="
                                strncpy(gStrbuf,(char *)&(buf[UDP_DATA_P+cmd_pos+2]),STR_BUFFER_SIZE-3);
                                gStrbuf[STR_BUFFER_SIZE-3]='\0';
                                gStrbuf[0]='n';
                                gStrbuf[1]='=';
                                strcpy(gStrbuf+2,gPrevValue);
                                goto ANSWER;
                        }
                        strcpy(gStrbuf,"e=no_cmd, usage: g|n=...");
ANSWER:
                        make_udp_reply_from_request(buf,gStrbuf,strlen(gStrbuf),myudpport);
                }
        }
        return (0);
}

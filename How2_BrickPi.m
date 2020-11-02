clear,clc
BR = BrickPi('192.168.xx.xx','user','passwort');

US1 = BPsensor('NXT_Ultrasonic',4);
GyroU = BPsensor(17,3);
GyroAlu = BPsensor('EV3_GYRO_ABS',1);
Button = BPsensor('TOUCH_NXT',2);

LM = BPmotor('A');
RM = BPmotor(2);
BR.add_motor(LM);
BR.add_motor(RM);
BR.add_sensor(US1);
BR.add_sensor(GyroU);
BR.add_sensor(GyroAlu);
BR.add_sensor(Button);
BR.init

BR.get_voltage_bat

out = BR.get_sensor(US1)
out = BR.get_sensor(GyroU)
out = BR.get_sensor(GyroAlu)
out = BR.get_sensor(Button)


BR.set_motor_power(LM,0)
BR.set_motor_power(LM,'float')

out=BR.get_motor_status(LM)
BR.offset_motor_encoder(LM,100);
BR.offset_motor_encoder(LM,100);
BR.get_motor_encoder(LM)

out=BR.get_motor_status(RM)
BR.set_motor_encoder(RM,123423)
BR.set_motor_encoder(RM,99999)
BR.get_motor_encoder(RM)
BR.reset_motor_encoder(RM)
BR.get_motor_encoder(RM)

BR.set_LED(50)


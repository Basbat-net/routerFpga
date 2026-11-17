# routerFpga

Router IPv4 sintetizable para una Nexys A7-100T
------------------------------------------------

El directorio `rtl/` contiene `ipv4_router.sv`, un núcleo de encaminamiento
IPv4 de bajo coste para conectar a una interfaz MAC/Ethernet. El núcleo recibe
la dirección destino de cada paquete mediante un handshake `valid/ready` y
devuelve el siguiente salto o una indicación de descarte. La tabla admite
entradas programables y utiliza *longest-prefix match*; si dos rutas tienen la
misma longitud, gana la de menor índice.

La Nexys A7-100T utiliza un reloj de 100 MHz. Este repositorio deja la
interfaz MAC y las restricciones de pines fuera del núcleo para evitar asumir
un PHY concreto; el archivo `.xdc` de la placa debe conectar el reloj, reset y
la MAC elegida por el diseño final.

### Simulación

Con Icarus Verilog instalado:

```sh
iverilog -g2012 -s ipv4_router_tb -o /tmp/ipv4_router_tb \
  rtl/ipv4_router.sv tb/ipv4_router_tb.sv
vvp /tmp/ipv4_router_tb
```

La salida esperada es `ipv4_router_tb: PASS`.
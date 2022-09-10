ak4619-cfg.hex: ak4619-cfg
	./ak4619-cfg > ak4619-cfg.hex

ak4619-cfg: ak4619-cfg.c
	gcc $< -o $@

clean:
	rm -rf ak4619-cfg.hex ak4619-cfg

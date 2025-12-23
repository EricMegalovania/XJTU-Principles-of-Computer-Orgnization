# 单周期 CPU 设计

从 MIPS-C 指令集中选择了 10 条，**地址总线** 和 **数据总线** 均为 32 位

## 指令选择

### R-R 运算指令 4 条

```assembly
add
sub
and
or
```

<img src="./img/image-20251223163243708.png" alt="image-20251223163243708" style="zoom: 80%;" />

<img src="./img/image-20251223163320393.png" alt="image-20251223163320393" style="zoom:80%;" />

<img src="./img/image-20251223163255677.png" alt="image-20251223163255677" style="zoom:80%;" />

<img src="./img/image-20251223163308520.png" alt="image-20251223163308520" style="zoom:80%;" />

### R-I 运算指令 2 条

```assembly
addi
ori
```

<img src="./img/image-20251223163203717.png" alt="image-20251223163203717" style="zoom:80%;" />

<img src="./img/image-20251223163215399.png" alt="image-20251223163215399" style="zoom:80%;" />

### 分支指令 2 条

```assembly
beq
j
```

<img src="./img/image-20251223163132472.png" alt="image-20251223163132472" style="zoom:80%;" />

<img src="./img/image-20251223163144216.png" alt="image-20251223163144216" style="zoom:80%;" />

### 加载指令 1 条

```assembly
lw
```

<img src="./img/image-20251223162710700.png" alt="image-20251223162710700" style="zoom:80%;" />

### 2.5 存储指令 1 条

```assembly
sw
```

<img src="./img/image-20251223162936037.png" alt="image-20251223162936037" style="zoom:80%;" />
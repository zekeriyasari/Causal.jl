# Writer 

## Basic Operation of Writers
Having `launch`ed, a `Writer` is triggered through its `trigger` pin. When triggered, a `Writer` reads its input and then writes it to its internal buffer `databuf`. When `databuf`  is full, the data in `databuf` is processed. Thus, the length of the data that is to be processed by the `Writer` is determined by the length of their internal buffer `databuf`. 

Let us construct a `Writer`. 
```@repl writer_ex
using Causal # hide 
w = Writer(input=Inport(), buflen=5)
```
The file of `w` is closed and the `trigger` pin of `w` is not writable. That is, it is not possible to trigger `w` from its `trigger` pin.
```@repl writer_ex
w.file 
w.trigger
```
To trigger `w`, we need to open and launch it, 
```@repl writer_ex
oport, trg, hnd = Outport(), Outpin(), Inpin{Bool}()
connect!(oport, w.input)
connect!(trg, w.trigger)
connect!(w.handshake, hnd)
open(w)
t = launch(w)
```
Now, the internal file of `w` is opened in read/write mode and its `trigger` pin is writable. 
```@repl writer_ex
w.file
w.trigger.link
```
Let us now trigger `w`. 
```@repl writer_ex
put!(trg, 1.)
```
The `input` of `w` is now readable and `handshake` pin is not readable since `w` have not signaled that its triggering is succeeded yet. To do that, we need to put a value to the `input` of `w`
```@repl writer_ex
put!(oport, [10.])
```
Now, `w` signalled that its step is succeeded. It read the data from its `input` and written it into is `databuf`. 
```@repl writer_ex 
hnd.link
take!(hnd)
w.databuf
```
Since the `databuf` is not full nothing is written to the `file` of `w`. 
```@repl writer_ex
w.file
```
Let us continue triggering `w` until the `databuf` of `w` is full.
```@repl writer_ex
for t in 2. : 5.
    put!(trg, t)
    put!(oport, [t * 10])
    take!(hnd)
end
```
Now check that the content of the `file` of `w`.
```@repl writer_ex 
w.file
```
Note that the content of `databuf` is written to the `file` of `w`. The operation of `w` can be terminated. 
```@repl writer_ex
put!(trg, NaN)
```
When terminated, the `file` of `w` is closed.
```@repl writer_ex
w.file
```


!!! note 
    In this example, `w` does not have a `plugin` so nothing has been derived or computed from the data in `databuf`. The data in `databuf` is just written to `file` of `w`. To further data processing, see [Plugins](@ref)

## Full API 
```@docs
Writer 
write!(writer::Writer, td, xd)
read(writer::Writer; flatten=true)
fread 
mv(writer::Writer, dst; force::Bool=false)
cp(writer::Writer, dst; force=false, follow_symlinks=false)
open(writer::Writer)
close(writer::Writer)
```
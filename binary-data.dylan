module: binary-data
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see LICENSE.txt in this distribution

define class <malformed-data-error> (<error>)
end;

define class <alignment-error> (<error>)
end;

define class <out-of-range-error> (<error>)
end;

define class <parse-error> (<error>)
end;

define constant <byte-sequence> = <stretchy-vector-subsequence>;
define constant <bit-vector> = <stretchy-bit-vector-subsequence>;

define constant $protocols = make(<table>);

define method find-protocol-aux (protocol :: <string>)
 => (res :: false-or(<class>))
  find-protocol-aux(as(<symbol>, protocol))
end;

define method find-protocol-aux (protocol :: <symbol>)
 => (res :: false-or(<class>))
  element($protocols, protocol, default: #f)
end;

define function find-protocol (name :: <string>)
 => (res :: <class>, frame-name :: <string>)
  let protocol-name = name;
  let res = find-protocol-aux(protocol-name);
  unless (res)
    protocol-name := concatenate("<", name, ">");
    res := find-protocol-aux(protocol-name);
    unless (res)
      protocol-name := concatenate("<", name, "-frame>");
      res := find-protocol-aux(protocol-name);
      unless (res)
        error("Protocol not found %s\n", name);
      end;
    end;
  end;
  values(res, protocol-name)
end;

define function find-protocol-field
    (protocol :: <class>, field-name :: <string>)
 => (res :: <field>)
  let field = find-field(field-name, fields(protocol));
  unless (field)
    error("Field %s in protocol %s not found\n", field-name, protocol.frame-name);
  end;
  field
end;


define abstract class <frame> (<object>)
end;

define open generic parse-frame
    (frame-type :: subclass(<frame>),
     packet :: <sequence>,
     #rest rest, #key, #all-keys)
 => (value :: <object>, next-unparsed :: <integer>);

define method parse-frame
    (frame-type :: subclass(<frame>),
     packet :: <sequence>,
     #rest rest, #key)
 => (value :: <object>, next-unparsed :: <integer>);
 let packet-subseq = as(<stretchy-byte-vector-subsequence>, packet);
 apply(parse-frame, frame-type, packet-subseq, rest)
end;


define open generic assemble-frame-into
    (frame :: <frame>, packet :: <byte-sequence>)
 => (length :: <integer>);

define open generic assemble-frame-into-as
    (frame-type :: subclass(<translated-frame>),
     data :: <object>,
     packet :: <byte-sequence>)
 => (length :: <integer>);


define generic assemble-frame (frame :: <frame>) => (packet /* :: <vector> */);

define method assemble-frame
    (frame :: <unparsed-container-frame>)
 => (packet :: <unparsed-container-frame>)
  frame
end;

define open generic high-level-type (low-level-type :: subclass(<frame>))
 => (res :: <type>);

define inline method high-level-type (object :: subclass(<frame>))
 => (res :: <type>)
  object
end;

define open generic fixup! (frame :: type-union(<container-frame>, <raw-frame>));

define method fixup! (frame :: type-union(<container-frame>, <raw-frame>))
end;

define method fixup! (frame :: <header-frame>)
  fixup!(frame.payload);
end;

define open generic container-frame-size (frame :: <container-frame>)
 => (length :: false-or(<integer>));

define open generic frame-size (frame :: <frame>)
 => (length :: <integer>);

define open generic summary (frame :: <frame>) => (summary :: <string>);

define method summary (frame :: <frame>) => (summary :: <string>)
  format-to-string("%=", frame.object-class)
end;

define abstract class <fixed-size-frame> (<frame>)
end;

define inline method frame-size (frame :: <fixed-size-frame>)
 => (length :: <integer>)
  field-size(frame.object-class);
end;

define abstract class <variable-size-frame> (<frame>)
end;

define abstract class <untranslated-frame> (<frame>)
end;

define abstract class <translated-frame> (<frame>)
end;

define abstract class <fixed-size-untranslated-frame>
    (<fixed-size-frame>, <untranslated-frame>)
end;

define abstract class <variable-size-untranslated-frame>
    (<variable-size-frame>, <untranslated-frame>)
end;

define open abstract class <container-frame> (<variable-size-untranslated-frame>)
  virtual constant slot frame-name :: <string>;
end;

define open generic frame-name
    (frame :: type-union(subclass(<container-frame>), <container-frame>))
 => (res :: <string>);

define inline method frame-name (frame :: <container-frame>) => (res :: <string>)
  frame-name(frame.object-class);
end;

define method frame-name (frame :: subclass(<container-frame>))
  => (res :: <string>)
  "anonymous"
end;

define open generic field-count (frame :: subclass(<container-frame>))
 => (res :: <integer>);

define inline method field-count (frame :: subclass(<container-frame>))
 => (res :: <integer>)
  field-count(unparsed-class(frame));
end;

define inline method field-count (frame :: subclass(<unparsed-container-frame>))
 => (res :: <integer>)
  0;
end;

define open generic fields
    (frame :: type-union(<container-frame>, subclass(<container-frame>)))
 => (res :: <simple-vector>);

define open generic fields-initializer (frame :: subclass(<container-frame>))
 => (res :: <simple-vector>);

define inline method fields-initializer (frame :: subclass(<container-frame>))
 => (fields :: <simple-vector>)
  as(<simple-object-vector>, #[])
end;

define open generic unparsed-class (type :: subclass(<container-frame>))
  => (class :: <class>);

define open generic decoded-class (type :: subclass(<container-frame>))
  => (class :: <class>);

define open generic layer-magic (frame :: <container-frame>) => (res);

define method layer-magic (frame :: <container-frame>) => (res)
  error("no magic field defined for protocol layering in protocol %s",
        frame.frame-name);
end;

define open abstract class <decoded-container-frame> (<container-frame>)
  slot concrete-frame-fields :: <vector>, init-keyword: ff:;
  slot parent :: false-or(<container-frame>) = #f, init-keyword: parent:;
end;

define function payload-type (frame :: <container-frame>) => (res :: <type>)
  lookup-layer(frame.object-class, frame.layer-magic) | <raw-frame>;
end;

define open generic lookup-layer
    (frame :: subclass(<frame>), value :: <integer>)
 => (class :: false-or(<class>));

define method lookup-layer (frame :: subclass(<frame>), value :: <integer>)
 => (false == #f)
  #f
end;

define open generic reverse-lookup-layer
    (frame :: subclass(<frame>), payload :: <frame>)
 => (value :: <integer>);

define inline method fixup-protocol-magic
    (frame :: <header-frame>) => (magic :: <integer>)
  reverse-lookup-layer(frame.object-class, frame.payload)
end;

define inline method fixup-protocol-magic
    (frame :: <container-frame>) => (magic :: <integer>)
  reverse-lookup-layer(frame.object-class, frame)
end;

define class <inline-layering-error> (<error>)
end;

define class <missing-inline-layering-error> (<error>)
end;

define method initialize
    (frame :: <decoded-container-frame>, #rest rest, #key ff, #all-keys)
  next-method();
  unless (ff)
    frame.concrete-frame-fields :=
      make(<vector>, size: field-count(frame.object-class), fill: #f);
  end
end;

define open abstract class <unparsed-container-frame> (<container-frame>)
  slot packet :: <byte-sequence>, init-keyword: packet:;
  constant slot cache :: <container-frame>, init-keyword: cache:;
end;

define method initialize
    (class :: <unparsed-container-frame>, #rest rest, #key parent, #all-keys)
  next-method();
  parent-setter(parent, class.cache);
end;

define inline method concrete-frame-fields (frame :: <unparsed-container-frame>)
 => (res :: <vector>)
  frame.cache.concrete-frame-fields
end;

define inline method parent (frame :: <unparsed-container-frame>)
 => (res :: false-or(<container-frame>))
  frame.cache.parent
end;

define inline method parent-setter
    (value :: false-or(<container-frame>), frame :: <unparsed-container-frame>)
 => (res :: false-or(<container-frame>))
  frame.cache.parent := value
end;

define method get-frame-field
    (field-index :: <integer>, frame :: <container-frame>)
 => (res :: <frame-field>)
  let res = frame.concrete-frame-fields[field-index];
  if (res)
    res
  else
    let frame-field = make(<frame-field>,
                           frame: frame,
                           field: fields(frame)[field-index]);
    frame.concrete-frame-fields[field-index] := frame-field;
    frame-field
  end;
end;

define method get-frame-field (name :: <symbol>, frame :: <container-frame>)
 => (res :: <frame-field>)
  let field = find-field(name, fields(frame));
  get-frame-field(field.index, frame)
end;

define function sorted-frame-fields (frame :: <container-frame>)
  map(method(x) get-frame-field(x.field-name, frame) end,
      fields(frame))
end;

define open abstract class <variably-typed-container-frame> (<container-frame>)
end;

define open abstract class <decoded-variably-typed-container-frame>
  (<variably-typed-container-frame>, <decoded-container-frame>)
end;

define open abstract class <unparsed-variably-typed-container-frame>
  (<variably-typed-container-frame>, <unparsed-container-frame>)
end;

define open abstract class <header-frame> (<container-frame>)
end;

define open abstract class <decoded-header-frame>
  (<header-frame>, <decoded-container-frame>)
end;

define open abstract class <unparsed-header-frame>
  (<header-frame>, <unparsed-container-frame>)
end;

define open generic source-address
    (frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic source-address-setter
    (value, frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic destination-address
    (frame :: type-union(<raw-frame>, <container-frame>)) => (res);

define open generic destination-address-setter
    (value, frame :: type-union(<raw-frame>, <container-frame>)) => (res);

//can't specify type because unparsed-getter can't return false-or(<frame>)!
define open generic payload (frame :: <header-frame>) => (payload);

define method payload (frame :: <header-frame>) => (payload)
  error("No payload specified");
end;

define open generic payload-setter
    (value /* :: false-or(<frame>) */, object :: <header-frame>)
 => (res /* :: false-or(<frame>) */);

define method frame-size (frame :: <container-frame>) => (res :: <integer>)
  block ()
    container-frame-size(frame)
  exception (e :: <error>)
    reduce1(\+, map(curry(get-field-size-aux, frame), frame.fields))
  end;
end;

define method assemble-frame (frame :: <container-frame>)
 => (packet :: <unparsed-container-frame>);
  let f = copy-frame(frame);
  assemble-frame!(f)
end;

define method assemble-frame! (frame :: <unparsed-container-frame>)
 => (res :: <unparsed-container-frame>)
  frame
end;

define method assemble-frame! (frame :: <decoded-container-frame>)
 => (packet :: <unparsed-container-frame>)
  let result = make(<stretchy-byte-vector-subsequence>,
                    data: make(<stretchy-byte-vector>, capacity: 1548));
  assemble-frame-into(frame, result);
  let uf = make(unparsed-class(frame.object-class),
                cache: frame,
                packet: result);
  fixup!(uf);
  uf
end;

define method as (type == <string>, frame :: <container-frame>)
 => (string :: <string>);
  apply(concatenate,
        format-to-string("%=\n", frame.object-class),
        map(method(field :: <field>)
              let field-value = field.getter(frame);
              let field-as-string
                = if (instance?(field-value, <collection>))
                    reduce(method(x, y) concatenate(x, " ", as(<string>, y)) end,
                           "", field-value)
                  else
                    as(<string>, field-value)
                  end;
              concatenate(as(<string>, field.field-name),
                          ": ",
                          field-as-string,
                          "\n")
            end, fields(frame)))
end;

define method copy-frame (frame :: <unparsed-container-frame>, #key par = #f)
 => (res :: <container-frame>)
  let my-cache = copy-frame(frame.cache, par: par);
  make(unparsed-class(frame.object-class),
       cache: my-cache,
       packet: as(<stretchy-byte-vector-subsequence>, copy-sequence(frame.packet)),
       parent: par | frame.parent)
end;

define method copy-frame (frame :: <decoded-container-frame>, #key par = #f)
 => (res :: <decoded-container-frame>)
  let res = make(decoded-class(frame.object-class),
                 ff: copy-sequence(frame.concrete-frame-fields));
  for (field in frame.fields)
    if (instance?(field, <repeated-field>))
      let r = map(method(x) copy-frame(x, par: res) end, field.getter(frame));
      field.setter(r, res);
    else
      field.setter(copy-frame(field.getter(frame), par: res), res);
    end;
  end;
  if (par)
    res.parent := par;
  end;
  res
end;

define method copy-frame (frame, #key par) => (res)
  frame
end;

define method assemble-frame-into
    (frame :: <container-frame>, packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  let offset :: <integer> = 0;
  for (field in fields(frame))
    if (field.getter(frame) == $unsupplied)
      if (field.fixup-function)
        field.setter(field.fixup-function(frame), frame);
      else
        error("No value for field %s while assembling", field.field-name);
      end;
    end;
    if (field.dynamic-start)
      let real-frame-start = field.dynamic-start(frame);
      if (real-frame-start ~= offset)
        //pad!
        //format-out("Need dynamic padding at start of %s : %d ~= %d\n",
        //           field.field-name, real-frame-start, offset);
      end;
      offset := real-frame-start;
    end;
    if ((field.static-start ~= $unknown-at-compile-time) & (field.static-start ~= offset))
      //format-out("Need static padding at start of %s : %d ~= %d\n",
      //           field.field-name, field.static-start, offset);
      offset := field.static-start;
    end;
    let ff = make(<frame-field>, field: field, frame: frame, start: offset);
    frame.concrete-frame-fields[field.index] := ff;
    let length = assemble-field-into(field, frame, subsequence(packet, start: offset));
    frame.concrete-frame-fields[field.index].%length := length;
    let end-off = offset + length;
    if (field.dynamic-end)
      let real-frame-end = field.dynamic-end(frame);
      if (real-frame-end ~= length)
        //pad!
        //format-out("Need dynamic padding at end of %s : %d ~= %d\n",
        //           field.field-name, real-frame-end, end-off);
      end;
      end-off := real-frame-end;
    end;
    if ((field.static-length ~= $unknown-at-compile-time) & (field.static-length  ~= length))
      end-off := offset + field.static-length;
    end;
    if ((field.static-end ~= $unknown-at-compile-time) & (field.static-end ~= end-off))
      //format-out("Need static padding at end of %s : %d ~= %d\n",
      //           field.field-name, field.static-end, end-off);
      end-off := field.static-end;
    end;
    if (offset + length ~= end-off)
      //format-out("also adjusting length of ff %d -> %d!\n",
      //           length, end-off - offset);
      frame.concrete-frame-fields[field.index].%length := end-off - offset;
    end;
    frame.concrete-frame-fields[field.index].%end-offset := end-off;
    if (instance?(field.getter(frame), <decoded-container-frame>))
      let unparsed = make(unparsed-class(field.getter(frame).object-class),
                          cache: field.getter(frame),
                          packet: subsequence(packet, start: offset, length: end-off),
                          parent: frame);
      field.setter(unparsed, frame);
    end;
    offset := end-off;
  end;
  offset
end;

define method assemble-frame-into
    (frame :: <unparsed-container-frame>,
     to-packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  let ff = frame.concrete-frame-fields;
  let start = if (ff.size > 0 & ff[0] & ff[0].start-offset)
                byte-offset(ff[0].start-offset);
              else
                0
              end;
  let len = if (ff.size > 0 & element(ff, ff.size - 1, default: #f))
              byte-offset(ff[ff.size - 1].end-offset)
            else
              frame.packet.size
            end;
  copy-bytes(to-packet, 0, frame.packet, start, len);
  (len - start) * 8
end;

define method assemble-field-into
    (field :: <enum-field>,
     frame :: <container-frame>,
     packet :: <stretchy-vector-subsequence>)
  let value = field.getter(frame);
  if (instance?(value, <symbol>))
    value := enum-field-symbol-to-int(field, value)
  end;
  assemble-aux(field.type, value, packet)
end;

define method assemble-field-into
    (field :: <single-field>,
     frame :: <container-frame>,
     packet :: <stretchy-vector-subsequence>)
  assemble-aux(field.type, field.getter(frame), packet)
end;

define method assemble-field-into
    (field :: <variably-typed-field>,
     frame :: <container-frame>,
     packet :: <stretchy-vector-subsequence>)
  assemble-frame-into(field.getter(frame), packet)
end;

define method assemble-field-into
    (field :: <repeated-field>,
     frame :: <container-frame>,
     packet :: <stretchy-vector-subsequence>)
  let offset :: <integer> = 0;
  let repeated-ff = frame.concrete-frame-fields[field.index];
  for (ele in field.getter(frame))
    let ff = make(<rep-frame-field>, start: offset, parent: repeated-ff, frame: frame);
    add!(repeated-ff.frame-field-list, ff);
    let length = assemble-aux(field.type, ele, subsequence(packet, start: offset));
    ff.%end-offset := offset + length;
    ff.%length := length;
    offset := length + offset;
  end;
  offset
end;

define method assemble-aux
    (frame-type :: subclass(<untranslated-frame>),
     frame :: <frame>,
     packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  assemble-frame-into(frame, packet)
end;

define method assemble-aux
    (frame-type :: subclass(<translated-frame>),
     frame :: <object>,
     packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  assemble-frame-into-as(frame-type, frame, packet)
end;

define open abstract class <position-mixin> (<object>)
  slot %start-offset :: false-or(<integer>) = #f, init-keyword: start:;
  slot %end-offset :: false-or(<integer>) = #f, init-keyword: end:;
  slot %length :: false-or(<integer>) = #f, init-keyword: length:;
end;

define class <rep-frame-field> (<position-mixin>)
  constant slot parent-frame-field :: <frame-field>,
    required-init-keyword: parent:;
  constant slot frame, required-init-keyword: frame:;
end;

define inline method start-offset (ff :: <position-mixin>)
  ff.%start-offset
end;

define inline method end-offset (ff :: <position-mixin>)
  ff.%end-offset
end;

define inline method length (ff :: <position-mixin>)
  ff.%length
end;

define class <frame-field> (<position-mixin>)
  constant slot field :: <field>, init-keyword: field:;
  constant slot frame :: <container-frame>, init-keyword: frame:;
end;

define class <repeated-frame-field> (<frame-field>)
  constant slot frame-field-list :: <stretchy-vector> = make(<stretchy-vector>);
end;

define method make (class == <frame-field>, #rest rest, #key field, #all-keys)
 => (res :: <frame-field>)
  if (instance?(field, <repeated-field>))
    apply(make, <repeated-frame-field>, field: field, rest)
  else
    next-method()
  end;
end;

define inline method value (frame-field :: <frame-field>) => (res)
  frame-field.field.getter(frame-field.frame)
end;

define inline method start-offset (frame-field :: <frame-field>)
 => (res :: <integer>)
  unless (frame-field.%start-offset)
    let my-field = frame-field.field;
    if (my-field.static-start ~= $unknown-at-compile-time)
      frame-field.%start-offset := my-field.static-start;
      if (my-field.dynamic-start)
        error("found a gap: in %s knew start offset statically (%d), but got a dynamic offset (%d)\n",
              my-field.field-name, my-field.static-start, my-field.dynamic-start(frame-field.frame))
      end;
    elseif (my-field.dynamic-start)
      frame-field.%start-offset := my-field.dynamic-start(frame-field.frame);
    else
      if (my-field.index > 0)
        frame-field.%start-offset
          := end-offset(get-frame-field(my-field.index - 1, frame-field.frame));
      end;
    end;
  end;
  frame-field.%start-offset
end;

define inline function compute-field-length (frame-field :: <frame-field>)
 => (res :: false-or(<integer>))
  let my-field = frame-field.field;
  if (my-field.static-length ~= $unknown-at-compile-time)
    frame-field.%length := my-field.static-length;
    if (my-field.dynamic-length)
      error("found a gap: in %s knew length statically (%d), but got a dynamic offset (%d)\n",
            my-field.field-name, my-field.static-length, my-field.dynamic-length(frame-field.frame))
    end;
  elseif (my-field.dynamic-length)
    frame-field.%length := my-field.dynamic-length(frame-field.frame);
  end;
  frame-field.%length
end;

define inline method length (frame-field :: <frame-field>)
 => (res :: <integer>)
  unless (frame-field.%length)
    unless (compute-field-length(frame-field))
      value(frame-field); //XXX: b0rk3n
      unless (frame-field.%length)
        frame-field.%length := get-field-size-aux(frame-field.frame, frame-field.field);
      end;
    end;
  end;
  frame-field.%length
end;

define inline function compute-field-end (frame-field :: <frame-field>)
 => (res :: false-or(<integer>))
  let my-field = frame-field.field;
  if (my-field.static-end ~= $unknown-at-compile-time)
    frame-field.%end-offset := my-field.static-end;
    if (my-field.dynamic-end)
      error("found a gap: in %s knew end statically (%d), but got a dynamic end (%d)\n",
            my-field.field-name, my-field.static-end, my-field.dynamic-end(frame-field.frame));
    end;
  elseif (my-field.dynamic-end)
    frame-field.%end-offset := my-field.dynamic-end(frame-field.frame);
  end;
  frame-field.%end-offset
end;

define inline method end-offset (frame-field :: <frame-field>)
 => (res :: <integer>)
  unless (frame-field.%end-offset)
    unless (compute-field-end(frame-field))
      frame-field.%end-offset := frame-field.start-offset + frame-field.length;
    end;
  end;
  frame-field.%end-offset
end;

define sideways method print-object
    (frame-field :: <frame-field>, stream :: <stream>) => ();
  format(stream, "%s: %=", frame-field.field.field-name, frame-field.frame);
end;

define method get-field-size-aux
    (frame :: <container-frame>, field :: <statically-typed-field>)
 => (size :: <integer>)
  get-field-size-aux-aux(frame, field, field.type)
end;

define method get-field-size-aux
    (frame :: <container-frame>, field :: <variably-typed-field>)
 => (size :: <integer>)
  frame-size(field.getter(frame))
end;

define method get-field-size-aux
    (frame :: <container-frame>, field :: <repeated-field>)
 => (size :: <integer>)
  //XXX: refactor this whole crap
  let fs = field-size(field.type);
  if (fs & fs ~= $unknown-at-compile-time)
    fs * size(field.getter(frame))
  else
    reduce(\+, 0, map(frame-size, field.getter(frame)))
  end;
end;

define method get-field-size-aux-aux
    (frame :: <frame>,
     field :: <single-field>,
     frame-type :: subclass(<fixed-size-frame>))
 => (res :: <integer>)
  field-size(frame-type)
end;

define method get-field-size-aux-aux
    (frame :: <frame>,
     field :: <single-field>,
     frame-type :: subclass(<variable-size-untranslated-frame>))
 => (res :: <integer>)
  if (field.static-length ~= $unknown-at-compile-time)
    field.static-length
  else
    frame-size(field.getter(frame))
  end
end;

define method get-field-size-aux-aux
    (frame :: <frame>,
     field :: <single-field>,
     frame-type :: subclass(<variable-size-translated-leaf-frame>))
 => (res :: <integer>)
  //need to look for user-defined static size method
  //or assemble frame, cache it and get its size
  error("Not yet implemented!")
end;


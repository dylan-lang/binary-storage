Module:    dylan-user
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see LICENSE.txt in this distribution

define library binary-data
  use common-dylan;
  use io;

  export binary-data;
end library binary-data;

define module binary-data
  use common-dylan, exclude: { format-to-string };
  use byte-vector;
  use format;
  use print, import: { print-object };
  use streams;

  export <stretchy-vector-subsequence>,
    <stretchy-byte-vector-subsequence>,
    <stretchy-byte-vector>,
    subsequence,
    start-index, end-index,
    <out-of-bound-error>,
    encode-integer, decode-integer;

  export data,
    concrete-frame-fields,
    <repeated-field>;

  export byte-aligned, high-level-type;

  export n-byte-vector-definer, n-bit-unsigned-integer-definer;

  export hexdump;

  export <unsigned-byte>, <boolean-bit>,
    <3byte-big-endian-unsigned-integer>,
    <2byte-big-endian-unsigned-integer>, <2byte-little-endian-unsigned-integer>,
    <3byte-little-endian-unsigned-integer>,
    <1bit-unsigned-integer>, <2bit-unsigned-integer>, <3bit-unsigned-integer>,
    <4bit-unsigned-integer>, <5bit-unsigned-integer>, <6bit-unsigned-integer>,
    <7bit-unsigned-integer>, <9bit-unsigned-integer>, <10bit-unsigned-integer>,
    <11bit-unsigned-integer>, <12bit-unsigned-integer>, <13bit-unsigned-integer>,
    <14bit-unsigned-integer>, <15bit-unsigned-integer>, <20bit-unsigned-integer>;

  export <variable-size-byte-vector>, <externally-delimited-string>,
    <raw-frame>;

  export $empty-externally-delimited-string, $empty-raw-frame;

  //XXX: evil hacks
  export float-to-byte-vector-le, byte-vector-to-float-le,
    float-to-byte-vector-be, byte-vector-to-float-be,
    <big-endian-unsigned-integer-4byte>, big-endian-unsigned-integer-4byte,
    <little-endian-unsigned-integer-4byte>, little-endian-unsigned-integer-4byte,;

  export <null-frame>;

  export <fixed-size-translated-leaf-frame>, <byte-sequence>,
    <fixed-size-byte-vector-frame>;

  export <integer-or-unknown>, $unknown-at-compile-time;

  export <malformed-data-error>, <parse-error>;

  export <frame-field>,
    <repeated-frame-field>,
    <rep-frame-field>,
    <position-mixin>,
    parent-frame-field,
    frame-field-list,
    start-offset,
    length,
    end-offset,
    frame,
    field,
    value;

  export <field>,
    static-start,
    static-length,
    static-end,
    field-name,
    field-size,
    getter,
    setter,
    fixup-function,
    type;

  export <frame>,
    <leaf-frame>,
    parse-frame,
    assemble-frame,
    assemble-frame-into,
    assemble-frame-into-as,
    assemble-frame!,
    copy-frame,
    read-frame,
    summary;

  export sorted-frame-fields,
    get-frame-field,
    fields,
    find-protocol,
    find-protocol-field;

  export <container-frame>,
    <unparsed-container-frame>,
    <decoded-container-frame>,
    fields-initializer,
    frame-name,
    unparsed-class,
    decoded-class,
    field-count,
    fixup!,
    parent, parent-setter,
    packet, packet-setter,
    cache,
    source-address, source-address-setter,
    destination-address, destination-address-setter,
    payload-type,
    container-frame-size,
    layer-magic,
    lookup-layer, reverse-lookup-layer;

  export <header-frame>,
    <unparsed-header-frame>,
    <decoded-header-frame>,
    payload, payload-setter;

  export <inline-layering-error>,
    <missing-inline-layering-error>,
    <variably-typed-container-frame>,
    <unparsed-variably-typed-container-frame>,
    <decoded-variably-typed-container-frame>;

  export frame-size,
    byte-offset,
    bit-offset;

  //utilities
  export find-frame-field,
    compute-absolute-offset,
    compute-length,
    find-frame-at-offset;

  export binary-data-definer;
  //XXX: we shouldn't need to export those
  export real-class-definer, decoded-class-definer, gen-classes,
    frame-field-generator, summary-generator, enum-frame-field-generator,
    unparsed-frame-field-generator;
end module binary-data;

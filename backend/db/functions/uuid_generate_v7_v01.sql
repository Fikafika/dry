create extension if not exists pgcrypto;

create or replace function uuid_generate_v7()
returns uuid
as $$
declare
  output       bytea = e'\\000\\000\\000\\000\\000\\000\\000\\000\\000';
  timestamp    timestamptz;
  unix_ts_ms   bigint;
  rand_a       int;
begin
  timestamp = clock_timestamp();
  unix_ts_ms = floor(extract(epoch from timestamp) * 1000)::bigint;

  output = set_byte(output, 0, (unix_ts_ms >> 40)::bit(8)::int);
  output = set_byte(output, 1, (unix_ts_ms >> 32)::bit(8)::int);
  output = set_byte(output, 2, (unix_ts_ms >> 24)::bit(8)::int);
  output = set_byte(output, 3, (unix_ts_ms >> 16)::bit(8)::int);
  output = set_byte(output, 4, (unix_ts_ms >> 8)::bit(8)::int);
  output = set_byte(output, 5, unix_ts_ms::bit(8)::int);

  /* use milliseconds as a "fixed-length dedicated counter" in order to improve monotonicity (https://datatracker.ietf.org/doc/html/draft-peabody-dispatch-new-uuid-format-03#section-6.2 Method 1) */
  rand_a = floor((extract(epoch from timestamp) * 1000 - unix_ts_ms) * 1000)::int;

  output = set_byte(output, 6, (b'0111'||(rand_a >> 8)::bit(4))::bit(8)::int);
  output = set_byte(output, 7, rand_a::bit(8)::int);

  output = set_byte(output, 8, (b'10'||get_byte(gen_random_bytes(1), 0)::bit(6))::bit(8)::int);
  output = output || gen_random_bytes(7);

  return substring(output::text from 3)::uuid;
end
$$
language plpgsql
volatile;

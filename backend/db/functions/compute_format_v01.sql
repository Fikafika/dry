CREATE OR REPLACE FUNCTION compute_format(format integer) RETURNS varchar as $$
-- Convert the number of digits into an integer format
BEGIN
  RETURN lpad('fm', format + 2, '0');
END
$$ LANGUAGE plpgsql;

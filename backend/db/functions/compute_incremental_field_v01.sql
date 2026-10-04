CREATE OR REPLACE FUNCTION compute_incremental_field(prefix varchar, suffix varchar, sequence_name varchar, format1 integer, type1 integer, format2 integer, type2 integer,
format3 integer, type3 integer) RETURNS varchar AS $$
-- Concatenate the prefix, the increment and the suffix
BEGIN
  RETURN CONCAT(prefix, format_increment(sequence_name, format1, type1, format2, type2, format3, type3), suffix);
END
$$ LANGUAGE plpgsql;

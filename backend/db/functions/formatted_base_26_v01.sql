CREATE OR REPLACE FUNCTION formatted_base_26(value bigint, nb_expected_char integer) RETURNS varchar AS $$
-- Convert an integer into letters
DECLARE
  chars char[];
  ret varchar;
  val bigint;
BEGIN
  chars := ARRAY['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'];
  val := value;
  ret := '';
  IF val < 0 THEN
    val := val * -1;
  END IF;
  WHILE val != 0 LOOP
    ret := chars[(val % 26)+1] || ret;
    val := val / 26;
  END LOOP;
  IF nb_expected_char > 0 AND char_length(ret) < nb_expected_char THEN
    ret := lpad(ret, nb_expected_char, 'A');
  END IF;
  RETURN ret;
END;
$$ LANGUAGE plpgsql;

/* Create a default dataset for new studies */


DROP FUNCTION IF EXISTS src_lpodatas.fct_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE);

CREATE OR REPLACE FUNCTION src_lpodatas.fct_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) RETURNS INTEGER
AS
$$
DECLARE
    the_new_id INT ;
BEGIN
    IF (SELECT
            exists(SELECT
                       1
                       FROM
                           gn_meta.t_acquisition_frameworks
                       WHERE
                           acquisition_framework_name LIKE _name)) THEN
        SELECT
            id_acquisition_framework
            INTO the_new_id
            FROM
                gn_meta.t_acquisition_frameworks
            WHERE
                acquisition_framework_name = _name;
        RAISE NOTICE 'Acquisition framework named % already exists', _name;
    ELSE

        INSERT INTO
            gn_meta.t_acquisition_frameworks( acquisition_framework_name
                                            , acquisition_framework_desc
                                            , acquisition_framework_start_date
                                            , meta_create_date)
            VALUES
                (_name, _desc, _startdate, now())
            RETURNING id_acquisition_framework INTO the_new_id;
        RAISE NOTICE 'Acquisition framework named % inserted with id %', _name, the_new_id;
    END IF;
    RETURN the_new_id;
END
$$
    LANGUAGE plpgsql;

ALTER FUNCTION src_lpodatas.fct_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) OWNER TO geonature;

COMMENT ON FUNCTION src_lpodatas.fct_get_or_insert_basic_acquisition_framework(_name TEXT, _desc TEXT, _startdate DATE) IS 'function to basically create acquisition framework';

/* Function to basically create new dataset attached to an acquisition_framework find by name */

DROP FUNCTION IF EXISTS src_lpodatas.fct_get_or_insert_dataset_from_shortname(_shortname TEXT, _acname TEXT);

CREATE OR REPLACE FUNCTION src_lpodatas.fct_get_or_insert_dataset_from_shortname(_shortname TEXT,
                                                                                 _acname TEXT DEFAULT gn_commons.get_default_parameter(
                                                                                         'visionature_default_acquisition_framework')) RETURNS INTEGER
AS
$$
DECLARE
    the_id_dataset INT ;
BEGIN
    IF (_shortname IS NOT NULL AND (SELECT
                                        exists(SELECT
                                                   1
                                                   FROM
                                                       gn_meta.t_datasets
                                                   WHERE
                                                       dataset_shortname LIKE _shortname))) THEN
        SELECT id_dataset INTO the_id_dataset FROM gn_meta.t_datasets WHERE dataset_shortname LIKE _shortname;
        RAISE NOTICE 'Dataset shortnamed % already exists with id %', _shortname, the_id_dataset;
    ELSE
        INSERT INTO
            gn_meta.t_datasets( id_acquisition_framework
                              , dataset_name
                              , dataset_shortname
                              , dataset_desc
                              , marine_domain
                              , terrestrial_domain
                              , meta_create_date)
            VALUES
            ( src_lpodatas.fct_get_id_acquisition_framework_by_name(_acname)
            , '[' || coalesce(_shortname, gn_commons.get_default_parameter('visionature_default_dataset')) || '] Jeu de données compléter'
            , coalesce(_shortname, gn_commons.get_default_parameter('visionature_default_dataset'))
            , 'A compléter'
            , FALSE
            , TRUE
            , now())
            RETURNING id_dataset INTO the_id_dataset;
        RAISE NOTICE 'Dataset shortnamed % inserted with id %', _shortname, the_id_dataset;
        RETURN the_id_dataset;
    END IF;
    RETURN the_id_dataset;
END
$$
    LANGUAGE plpgsql;

ALTER FUNCTION src_lpodatas.fct_get_or_insert_dataset_from_shortname(_shortname TEXT, _acname TEXT) OWNER TO geonature;

COMMENT ON FUNCTION src_lpodatas.fct_get_or_insert_dataset_from_shortname(_shortname TEXT, _acname TEXT) IS 'function to basically create acquisition framework';

/* TESTS */
--
-- SELECT gn_meta.create_default_dataset_with_shortname('<unclassified>', 'test');
-- DELETE
--     FROM
--         gn_meta.t_datasets
--     WHERE
--             id_acquisition_framework IN
--             (SELECT
--                  id_acquisition_framework
--                  FROM
--                      gn_meta.t_acquisition_frameworks
--                  WHERE
--                      acquisition_framework_name LIKE '<unclassified>');


/* New function to get acquisition framework id by name */

DROP FUNCTION IF EXISTS src_lpodatas.fct_get_id_acquisition_framework_by_name(_name TEXT);

CREATE OR REPLACE FUNCTION src_lpodatas.fct_get_id_acquisition_framework_by_name(_name TEXT) RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    theidacquisitionframework INTEGER;
BEGIN
    --Retrouver l'id du module par son code
    SELECT INTO theidacquisitionframework
        id_acquisition_framework
        FROM
            gn_meta.t_acquisition_frameworks
        WHERE
            acquisition_framework_name ILIKE _name
        LIMIT 1;
    RETURN theidacquisitionframework;
END;
$$;

ALTER FUNCTION src_lpodatas.fct_get_id_acquisition_framework_by_name(_name TEXT) OWNER TO geonature;

COMMENT ON FUNCTION src_lpodatas.fct_get_id_acquisition_framework_by_name(_name TEXT) IS 'function to get acquisition framework id by name';

/* New function to get dataset id by shortname */

DROP FUNCTION IF EXISTS src_lpodatas.fct_get_id_dataset_by_shortname(_shortname TEXT);

CREATE OR REPLACE FUNCTION src_lpodatas.fct_get_id_dataset_by_shortname(_shortname TEXT) RETURNS INTEGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    theiddataset INTEGER;
BEGIN
    --Retrouver l'id du module par son code
    SELECT INTO theiddataset
        id_dataset
        FROM
            gn_meta.t_datasets
        WHERE
            dataset_shortname ILIKE _shortname;
    RETURN theiddataset;
END;
$$;

ALTER FUNCTION src_lpodatas.fct_get_id_dataset_by_shortname(_shortname TEXT) OWNER TO geonature;

COMMENT ON FUNCTION src_lpodatas.fct_get_id_dataset_by_shortname(_shortname TEXT) IS 'function to get dataset id by shortname';

--SELECT gn_meta.get_id_dataset_by_shortname('dbChiroGCRA');


/* Create default acquisition framework */




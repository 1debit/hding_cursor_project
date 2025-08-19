import sys
import timeit

import snowflake.connector
from chime_ml.common import common_cfg
from chime_ml.common.data.snowflake_connector import SnowflakeConnector
from chime_ml.common.log import init_logger

logger = init_logger(__name__)


def main(argv):
    logger.info(argv)
    query = """
       select * from CHIME_EDW.FEATURE_STORE.GALILEO_TRANSACTION_FEATURES;
    """
    no_cache_query = """
       ALTER SESSION SET USE_CACHED_RESULT = FALSE;
    """
    logger.info(f"Running query: {query}")
    conn = None
    try:
        if argv and argv[0] == "chime_ml_common":
            logger.info("Running ML common based connector")
            conn = SnowflakeConnector()
            logger.info("Running no cache query")
            conn.run_query(no_cache_query)
            logger.info("Running data query")
            result_df = conn.run_query(query)
            logger.info(f"Total # of records: {len(result_df.index)}")
            logger.info(f"DF cols: {result_df.columns}")
            conn.close()
        else:
            logger.info("Running snowflake connector supported pandas function")
            snowflake_cred = common_cfg.get_snowflake_cred()
            with snowflake.connector.connect(
                user=snowflake_cred["user"],
                password=snowflake_cred["password"],
                account=snowflake_cred["account"],
            ) as ctx:
                cur = ctx.cursor()
                logger.info("Running no cache query")
                cur.execute(no_cache_query)
                logger.info("Running data query")
                cur.execute(query)
                result_df = cur.fetch_pandas_all()
                result_df.columns = result_df.columns.str.lower()
                logger.info(f"Total # of records: {len(result_df.index)}")
                logger.info(f"DF cols: {result_df.columns}")
    except Exception as e:
        logger.error(f"Error: {e}")
    finally:
        if conn:
            conn.close()


if __name__ == "__main__":
    start = timeit.default_timer()
    main(sys.argv[1:])
    stop = timeit.default_timer()
    total_time = stop - start
    logger.info(f"Total time: {total_time}")

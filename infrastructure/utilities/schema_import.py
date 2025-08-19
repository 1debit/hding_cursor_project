# https://github.com/1debit/data-security/blob/71b9c393eec1b2a019823c7448956ac98d6fbf82/source/access_control/create_schema_access_roles.sql#L17

TEMPLATE = (
	# Schema
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_schema.schema\n'
	'\tid = "{database}|{schema}"\n'
	'}}\n'
	# Roles
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_role.owner_role\n'
	'\tid = "{role_prefix}__OWNER"\n'
	'}}\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_role.writer_role\n'
	'\tid = "{role_prefix}__WRITER"\n'
	'}}\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_role.reader_role\n'
	'\tid = "{role_prefix}__READER"\n'
	'}}\n'
	# Non-Idempotent Grants
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.owner_schema_grant\n'
	'\tid = "{role_prefix}__OWNER|OWNERSHIP|false|true|false|false|true|false|false|false||||false|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_stage_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||STAGES|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_pipe_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||PIPES|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_table_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||TABLES|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_view_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||VIEWS|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_function_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||FUNCTIONS|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_file_format_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||FILE FORMATS|true|{database}.{schema}|false|"\n'
	'}}'
	'\n'
	'import {{\n'
	'\tto = module.{module_prefix}__schema.snowflake_grant_privileges_to_role.writer_future_sequence_grant\n'
	'\tid = "{role_prefix}__WRITER|OWNERSHIP|false|false|false|false|false|true|false|true|||SEQUENCES|true|{database}.{schema}|false|"\n'
	'}}'
)


def generate_import_resources(database: str, schema: str) -> None:
	database, schema = database.upper(), schema.upper()
	module_prefix = '__'.join([database,schema]).lower()
	role_prefix = '__'.join([database,schema])
	print(TEMPLATE.format(module_prefix=module_prefix,database=database,schema=schema,role_prefix=role_prefix))

# Make sure to do do this first:
# CALL operation_db.security.create_schema_access_roles('SEGMENT', 'CHIME_PROD');
schemas =[
	("ANALYTICS","LOOKER")
]


def main():
	for s in schemas:
		db, schema = s[0], s[1]
		generate_import_resources(db, schema)

if __name__ == '__main__':
    main()

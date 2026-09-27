setup_awscli_credential() {
	if ! which aws >/dev/null 2>&1; then
		sudo snap install aws-cli --classic || true
	fi

	local aws_dir="${TEST_DIR}/aws"
	export AWS_SHARED_CREDENTIALS_FILE="${aws_dir}/credentials"
	export AWS_CONFIG_FILE="${aws_dir}/config"
	export AWS_PROFILE=default
	if [ -f "${AWS_SHARED_CREDENTIALS_FILE}" ] &&
		[ -f "${AWS_CONFIG_FILE}" ] &&
		grep -q "aws_secret_access_key" "${AWS_SHARED_CREDENTIALS_FILE}"; then
		return
	fi

	local credentials_file="${HOME}/.local/share/juju/credentials.yaml"
	local access_key secret_key
	access_key=$(yq -r '[.credentials.aws // {} | to_entries[].value | select(.["access-key"] != null and .["secret-key"] != null)][0]["access-key"] // ""' "${credentials_file}" 2>/dev/null || true)
	secret_key=$(yq -r '[.credentials.aws // {} | to_entries[].value | select(.["access-key"] != null and .["secret-key"] != null)][0]["secret-key"] // ""' "${credentials_file}" 2>/dev/null || true)

	install -d -m 700 "${aws_dir}"
	printf '[default]\nregion = us-east-1\n' >"${AWS_CONFIG_FILE}"
	if [ -z "${access_key}" ] || [ -z "${secret_key}" ]; then
		echo "setup_awscli_credential: no aws access-key/secret-key in ${credentials_file}, relying on ambient credentials" >&2
		rm -f "${AWS_SHARED_CREDENTIALS_FILE}"
		return
	fi

	{
		echo "[default]"
		echo "aws_access_key_id = ${access_key}"
		echo "aws_secret_access_key = ${secret_key}"
	} >"${AWS_SHARED_CREDENTIALS_FILE}"
	chmod 600 "${AWS_SHARED_CREDENTIALS_FILE}" "${AWS_CONFIG_FILE}"
}

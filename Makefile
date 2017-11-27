SHELL := /bin/sh

.PHONY: test test_decompress test_recompress \
	decompress recompress \
	fail fail_decompress fail_recompress \
	clean clean_out clean_bin

PYTHON := /usr/bin/env python3
MOZLZ4 := ./mozlz4.py
ORIGINAL := ./test/original_search.json.mozlz4
DECOMPRESSED := ./test/decompressed_search.json
RECOMPRESSED := ./test/recompressed_search.json.mozlz4
DECOMPRESS_ERR := "ERROR: *** NO valid JSON produced. *** (${DECOMPRESSED})"
RECOMPRESS_ERR := "ERROR: *** Recompressed file NOT identical to original. *** (${ORIGINAL} vs ${RECOMPRESSED})"


test: clean test_decompress test_recompress

test_decompress: ${MOZLZ4} ${ORIGINAL} ${DECOMPRESSED}
	# Test decompressed JSON validity.
	${PYTHON} -m json.tool <${DECOMPRESSED} >/dev/null; EXIT_CODE=$$?; \
		if [ "$$EXIT_CODE" != "0" ]; then echo ${DECOMPRESS_ERR}; fi; \
		exit $$EXIT_CODE

test_recompress: ${MOZLZ4} ${ORIGINAL} ${RECOMPRESSED}
	# Test recompressed against original compressed.
	/usr/bin/cmp --silent ${ORIGINAL} ${RECOMPRESSED}; EXIT_CODE=$$?; \
		if [ "$$EXIT_CODE" != "0" ]; then echo ${RECOMPRESS_ERR}; fi; \
		exit $$EXIT_CODE


decompress: ${DECOMPRESSED} ${MOZLZ4} ${ORIGINAL}
${DECOMPRESSED}: ${MOZLZ4} ${ORIGINAL}
	# Decompress.
	${PYTHON} ${MOZLZ4} --decompress ${ORIGINAL} ${DECOMPRESSED}

recompress: ${RECOMPRESSED} ${MOZLZ4} ${DECOMPRESSED}
${RECOMPRESSED}: ${MOZLZ4} ${DECOMPRESSED}
	# Recompress.
	${PYTHON} ${MOZLZ4} ${DECOMPRESSED} ${RECOMPRESSED}


fail: fail_decompress fail_recompress

# IMPLEMENTATION NOTE: The "(exit <0-255>);" command - the parentheses being
#   ESSENTIAL here - causes a SUBSHELL to exit with the given exit code, which
#   we can then capture, in order to exit with at the very end of the rule.
#   If we did the `exit` directly in the current, top-level, shell, rather than
#   in a subshell, then `make` would bail at that point, and we would never
#   print the error message.
#   This subtle trick is really neato!

fail_decompress: ${MOZLZ4} ${ORIGINAL} ${DECOMPRESSED}
	# Fake decompress error.
	@# The difference between this "fail" rule and the real "test" rule is the
	@#   `(exit 255);`. See IMPLEMENTATION NOTE above.
	${PYTHON} -m json.tool <${DECOMPRESSED} >/dev/null; (exit 255); EXIT_CODE=$$?; \
		if [ "$$EXIT_CODE" != "0" ]; then echo ${DECOMPRESS_ERR}; fi; \
		exit $$EXIT_CODE

fail_recompress: ${MOZLZ4} ${ORIGINAL} ${RECOMPRESSED}
	# Fake recompress error.
	@# The difference between this "fail" rule and the real "test" rule is the
	@#   `(exit 255);`. See IMPLEMENTATION NOTE above.
	/usr/bin/cmp --silent ${ORIGINAL} ${RECOMPRESSED}; (exit 254); EXIT_CODE=$$?; \
		if [ "$$EXIT_CODE" != "0" ]; then echo ${RECOMPRESS_ERR}; fi; \
		exit $$EXIT_CODE


clean: clean_out clean_bin

clean_out:
	# Clean old output.
	rm -f ${DECOMPRESSED} ${RECOMPRESSED}

clean_bin:
	# Clean binary artifacts.
	rm -f ./*.pyc ./*.pyo; rm -rf ./__pycache__/


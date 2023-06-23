ENDPOINT ?= firehose-us-east-2.internal.dev.atherdigital.net:8545
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SINK_RANGE := "0:"

.PHONY: build
build:
	cargo build --target wasm32-unknown-unknown --release

.PHONY: stream_csv
stream_csv: build
	substreams run -e $(ENDPOINT) substreams.yaml csv_out -s 0 -t +10

.PHONY: stream_jsonl
stream_jsonl: build
	substreams run --plaintext -e $(ENDPOINT) substreams.yaml jsonl_out -s 0 -t +10


.PHONY: protogen
protogen:
	substreams protogen ./substreams.yaml --exclude-paths="sf/substreams,google"

.PHONY: sink_entities_to_files
sink_entities_to_files: build
	substreams-sink-files \
	run \
	$(ENDPOINT) \
	"$(ROOT_DIR)/substreams.yaml" \
	map_transfers \
	"$(ROOT_DIR)/sink-files/out" \
	--encoder="proto:.transfers[]" \
	--file-working-dir="$(ROOT_DIR)/sink-files/working" \
	--state-store="$(ROOT_DIR)/sink-files/workdir/state.yaml" \
	$(SINK_RANGE)

.PHONY: sink_lines_to_files
sink_lines_to_files: build
	substreams-sink-files \
	run -p \
	$(ENDPOINT) \
	"$(ROOT_DIR)/substreams.yaml" \
	jsonl_out \
	"$(ROOT_DIR)/sink-files/out" \
	--encoder="lines" \
	--file-working-dir="$(ROOT_DIR)/sink-files/working" \
	--state-store="$(ROOT_DIR)/sink-files/workdir/state.yaml" \
	$(SINK_RANGE)

.PHONY: package
package: build
	substreams pack -o substreams.spkg ./substreams.yaml

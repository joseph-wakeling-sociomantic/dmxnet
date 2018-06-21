# Ensure D2 unittests will fail if stomping prevention is triggered
export ASSERT_ON_STOMPING_PREVENTION=1

override DFLAGS += -w
override LDFLAGS += -lmxnet

ifeq ($(DVER),1)
	override DFLAGS += -v2 -v2=-static-arr-params -v2=-volatile
endif

.PHONY: download-mnist
download-mnist: $C/script/download-mnist
	$(call exec,sh $(if $V,,-x) $^,$(MNIST_DATA_DIR),$^)

# helper template to define targets for per-engine test runs
define run_test_with_engine
$(1).stamp: $(1)-$(2).stamp

$(1)-$(2).stamp: $1
	$(call exec,MXNET_ENGINE_TYPE=$2 $1,$1,$2)
endef

# helper function to generate targets for per-engine test runs
test_with_engines = $(foreach engine,$(TEST_MXNET_ENGINES),\
	$(eval $(call run_test_with_engine,$1,$(engine))))

# extra build dependencies for integration tests
$O/test-mxnet: override LDFLAGS += -lz
$O/test-mxnet: override DFLAGS += -debug=MXNetHandleManualFree

# run integration tests with all specified engines
$(eval $(call test_with_engines,$O/test-mxnet))

# extra runtime dependencies for integration tests
$O/test-mxnet.stamp: override ITFLAGS += $(MNIST_DATA_DIR)
$O/test-mxnet.stamp: download-mnist
	$Vtouch $@ # override default implementation

$O/%unittests: override LDFLAGS += -lz

# run unittests with all specified engines
$(eval $(call test_with_engines,$O/allunittests))

$O/allunittests.stamp:
	$Vtouch $@ # override default implementation

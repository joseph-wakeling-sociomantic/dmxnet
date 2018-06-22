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
#
# Params:
#     $1 = path to executable that runs tests
#     $2 = name of MXNet engine to use
define test_with_engine
$(1).stamp: $(1)-$(2).stamp

$(1)-$(2).stamp: $1
	$(call exec,MXNET_ENGINE_TYPE=$2 $1,$1,$2)
	$Vtouch $$@
endef

# helper function to generate targets for per-engine test runs
#
# Params:
#     $1 = path to executable that runs tests
define run_test_with_engines
$(foreach engine,$(TEST_MXNET_ENGINES),\
	$(eval $(call test_with_engine,$1,$(engine))))

$(1).stamp:
	$Vtouch $$@  # override default implementation
endef

define run_test_with_dependency
$(foreach engine,$(TEST_MXNET_ENGINES),\
	$(eval $(1)-$(engine).stamp: $2))
endef

# extra build dependencies for integration tests
$O/test-mxnet: override LDFLAGS += -lz
$O/test-mxnet: override DFLAGS += -debug=MXNetHandleManualFree

# extra runtime dependencies for integration tests
$(eval $(call run_test_with_dependency,$O/test-mxnet,\
	override ITFLAGS += $(MNIST_DATA_DIR)))
$(eval $(call run_test_with_dependency,$O/test-mxnet,\
	download-mnist))

# run integration tests with all specified engines
$(eval $(call run_test_with_engines,$O/test-mxnet))

$O/%unittests: override LDFLAGS += -lz

# run unittests with all specified engines
$(eval $(call run_test_with_engines,$O/allunittests))

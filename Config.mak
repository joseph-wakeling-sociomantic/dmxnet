INTEGRATIONTEST := integrationtest

TEST_MXNET_ENGINES ?= NaiveEngine ThreadedEngine ThreadedEnginePerDevice

MXNET_ENGINE_TYPE ?= NaiveEngine
export MXNET_ENGINE_TYPE

ifeq ($(DVER),2)
	DC ?= dmd-transitional
endif

gofer {
  rpc_agent_addr = try(env.CFG_GOFER_RPC_ADDR, "gofer.local:9200")
}
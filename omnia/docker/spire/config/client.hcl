spire {
  rpc_agent_addr  = try(env.CFG_SPIRE_RPC_ADDR, "spire.local:9100")
}
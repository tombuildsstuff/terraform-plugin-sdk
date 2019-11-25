package plugin

import (
	"context"

	"github.com/hashicorp/terraform-plugin-sdk/experimental/schema"
	proto "github.com/hashicorp/terraform-plugin-sdk/internal/tfplugin5"
)

func NewProviderServer(p *schema.Provider) func() proto.ProviderServer {
	if p == nil {
		// TODO - return error?
	}

	return func() proto.ProviderServer {
		return &ProviderServer{p}
	}
}

type ProviderServer struct {
	provider *schema.Provider
}

func (s *ProviderServer) GetSchema(ctx context.Context, req *proto.GetProviderSchema_Request) (*proto.GetProviderSchema_Response, error) {
	return nil, nil
}

func (s *ProviderServer) PrepareProviderConfig(ctx context.Context, req *proto.PrepareProviderConfig_Request) (*proto.PrepareProviderConfig_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ValidateResourceTypeConfig(ctx context.Context, req *proto.ValidateResourceTypeConfig_Request) (*proto.ValidateResourceTypeConfig_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ValidateDataSourceConfig(ctx context.Context, req *proto.ValidateDataSourceConfig_Request) (*proto.ValidateDataSourceConfig_Response, error) {
	return nil, nil
}

func (s *ProviderServer) UpgradeResourceState(ctx context.Context, req *proto.UpgradeResourceState_Request) (*proto.UpgradeResourceState_Response, error) {
	return nil, nil
}

func (s *ProviderServer) Stop(ctx context.Context, req *proto.Stop_Request) (*proto.Stop_Response, error) {
	return nil, nil
}

func (s *ProviderServer) Configure(ctx context.Context, req *proto.Configure_Request) (*proto.Configure_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ReadResource(ctx context.Context, req *proto.ReadResource_Request) (*proto.ReadResource_Response, error) {
	return nil, nil
}

func (s *ProviderServer) PlanResourceChange(ctx context.Context, req *proto.PlanResourceChange_Request) (*proto.PlanResourceChange_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ApplyResourceChange(ctx context.Context, req *proto.ApplyResourceChange_Request) (*proto.ApplyResourceChange_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ImportResourceState(ctx context.Context, req *proto.ImportResourceState_Request) (*proto.ImportResourceState_Response, error) {
	return nil, nil
}

func (s *ProviderServer) ReadDataSource(ctx context.Context, req *proto.ReadDataSource_Request) (*proto.ReadDataSource_Response, error) {
	return nil, nil
}

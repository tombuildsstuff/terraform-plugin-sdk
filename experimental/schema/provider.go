package schema

type Provider struct {
	// TODO
}

type Schema struct {
	Type     TODO
	Optional bool
	ForceNew bool
}

type Resource struct {
	Create CreateFunc
	Read   ReadFunc
	Update UpdateFunc
	Delete DeleteFunc

	Schema map[string]*Schema
}

type CreateFunc func(ctx context.Context, cd CreateData) *Diagnostics

type ReadFunc func(ctx context.Context, rd ReadData) *Diagnostics

type UpdateFunc func(ctx context.Context, ud UpdateData) *Diagnostics

type DeleteFunc func(ctx context.Context, dd DeleteData) *Diagnostics

type CreateData interface{}
type ReadData interface {
	Get(p Path) (TODO, error)
	GetFromConfig(p Path) (TODO, error)
}
type UpdateData interface{}
type DeleteData interface{}

type Path interface{}

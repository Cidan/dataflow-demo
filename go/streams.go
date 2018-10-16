package main

import (
	"context"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/options/gcpopts"
)

func main() {

	beam.Init()
	ctx := context.Background()
	project := gcpopts.GetProject(ctx)

	p := beam.NewPipeline()
	s := p.Root()

}

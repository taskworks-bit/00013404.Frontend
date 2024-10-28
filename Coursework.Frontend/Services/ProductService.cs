using Coursework.Frontend.Models;
using RestSharp;

namespace Coursework.Frontend.Services;

public class ProductService(RestClient client)
{
    public async Task<IEnumerable<Product>?> GetAllProductsAsync()
    {
        var request = new RestRequest("products", Method.Get);
        var response = await client.ExecuteAsync<IEnumerable<Product>>(request);

        if (!response.IsSuccessful)
        {
            throw new Exception($"Error retrieving products: {response.ErrorMessage}");
        }

        return response.Data;
    }

    public async Task<Product?> GetProductByIdAsync(long id)
    {
        var request = new RestRequest($"products/{id}", Method.Get);
        var response = await client.ExecuteAsync<Product>(request);

        if (!response.IsSuccessful)
        {
            throw new Exception($"Error retrieving product with ID {id}: {response.ErrorMessage}");
        }

        return response.Data;
    }

    public async Task CreateProductAsync(Product product)
    {
        var request = new RestRequest("products", Method.Post);
        request.AddJsonBody(product);

        var response = await client.ExecuteAsync(request);

        if (!response.IsSuccessful)
        {
            throw new Exception($"Error creating product: {response.ErrorMessage}");
        }
    }

    public async Task UpdateProductAsync(long id, Product product)
    {
        var request = new RestRequest($"products/{id}", Method.Put);
        request.AddJsonBody(product);

        var response = await client.ExecuteAsync(request);

        if (!response.IsSuccessful)
        {
            throw new Exception($"Error updating product with ID {id}: {response.ErrorMessage}");
        }
    }

    public async Task DeleteProductAsync(long id)
    {
        var request = new RestRequest($"products/{id}", Method.Delete);

        var response = await client.ExecuteAsync(request);

        if (!response.IsSuccessful)
        {
            throw new Exception($"Error deleting product with ID {id}: {response.ErrorMessage}");
        }
    }
}

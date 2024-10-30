using Coursework.Frontend.Models;
using Coursework.Frontend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging; // Include this using directive

namespace Coursework.Frontend.Controllers // Adjust to your project's namespace
{
    public class ProductController(ProductService productService, ILogger<ProductController> logger)
        : Controller
    {
        // Add a logger field

        // Inject logger

        public async Task<IActionResult> Index()
        {
            logger.LogInformation("Fetching all products.");
            var products = await productService.GetAllProductsAsync();
            return View(products);
        }

        public async Task<IActionResult> Details(int id)
        {
            logger.LogInformation("Fetching details for product ID {ProductId}.", id);
            var product = await productService.GetProductByIdAsync(id);
            return product == null ? NotFound() : View(product);
        }

        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ProductViewModel product)
        {
            if (ModelState.IsValid)
            {
                logger.LogInformation("Creating a new product.");
                await productService.CreateProductAsync(product);
                return RedirectToAction(nameof(Index));
            }
            return View(product);
        }

        public async Task<IActionResult> Edit(int id)
        {
            logger.LogInformation("Fetching product ID {ProductId} for editing.", id);
            var product = await productService.GetProductByIdAsync(id);
            return product == null ? NotFound() : View(product);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Product product)
        {
            if (ModelState.IsValid)
            {
                logger.LogInformation("Updating product ID {ProductId}.", id);
                await productService.UpdateProductAsync(id, product);
                return RedirectToAction(nameof(Index));
            }
            return View(product);
        }

        [HttpGet]
        public async Task<IActionResult> Delete(long id)
        {
            logger.LogInformation("Deleting product ID {ProductId}.", id);
            await productService.DeleteProductAsync(id);
            return RedirectToAction(nameof(Index));
        }
    }
}
